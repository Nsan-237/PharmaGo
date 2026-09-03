import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/gemini_service.dart';

// ─── Chat Message Model ──────────────────────────────────────────────────────

class _ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;
  final bool isStreaming;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
    this.isStreaming = false,
  });

  _ChatMessage copyWith({String? text, bool? isTyping, bool? isStreaming}) {
    return _ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      isTyping: isTyping ?? this.isTyping,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

// ─── Symptom Checker Screen ──────────────────────────────────────────────────

class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() =>
      _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Suggested quick symptom chips
  final List<String> _quickSymptoms = [
    'Fever & chills',
    'Headache',
    'Cough & sore throat',
    'Stomach pain',
    'Fatigue',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Greeting message from PharmAI
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final isFr = ref.read(localeProvider) == AppLanguage.fr;
      setState(() {
        _messages.add(
          _ChatMessage(
            id: 'greeting',
            text: isFr
                ? '👋 Bonjour ! Je suis **PharmAI**, votre assistant médical intelligent.\n\nDécrivez vos symptômes et je vous aiderai à comprendre ce qui pourrait se passer — en suggérant des causes possibles et des conseils simples.\n\n*Comment puis-je vous aider aujourd\'hui ?*'
                : '👋 Hello! I\'m **PharmAI**, your intelligent medical assistant.\n\nDescribe your symptoms and I\'ll help you understand what might be happening — suggesting possible causes and simple advice.\n\n*How can I help you today?*',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? quickMessage]) async {
    final text = (quickMessage ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    final userMsg = _ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final typingMsgId = 'typing-${DateTime.now().millisecondsSinceEpoch}';
    final typingMsg = _ChatMessage(
      id: typingMsgId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );

    setState(() {
      _messages.add(userMsg);
      if (quickMessage == null) _textController.clear();
      _isLoading = true;
      _messages.add(typingMsg);
    });

    _scrollToBottom();

    try {
      // Get streaming response from Gemini
      final streamId = 'ai-${DateTime.now().millisecondsSinceEpoch}';
      String accumulatedText = '';
      bool replacedTyping = false;

      await for (final chunk in GeminiService.streamSymptomAnalysis(text)) {
        if (!mounted) break;
        accumulatedText += chunk;

        setState(() {
          if (!replacedTyping) {
            // Replace typing indicator with streaming message
            final idx = _messages.indexWhere((m) => m.id == typingMsgId);
            if (idx != -1) {
              _messages[idx] = _ChatMessage(
                id: streamId,
                text: accumulatedText,
                isUser: false,
                timestamp: DateTime.now(),
                isStreaming: true,
              );
            }
            replacedTyping = true;
          } else {
            // Update streaming message
            final idx = _messages.indexWhere((m) => m.id == streamId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(text: accumulatedText);
            }
          }
        });

        _scrollToBottom();
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Mark streaming as complete
      if (mounted) {
        setState(() {
          final streamIdx = _messages.indexWhere(
            (m) => m.id == streamId || m.id == typingMsgId,
          );
          if (streamIdx != -1) {
            _messages[streamIdx] = _messages[streamIdx].copyWith(
              text: accumulatedText.isNotEmpty
                  ? accumulatedText
                  : GeminiService.analyzeSymptoms(text) as String,
              isStreaming: false,
              isTyping: false,
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Remove typing indicator and show error
        setState(() {
          _messages.removeWhere((m) => m.id == typingMsgId);
          _messages.add(
            _ChatMessage(
              id: 'error-${DateTime.now().millisecondsSinceEpoch}',
              text: ref.read(localeProvider) == AppLanguage.fr
                  ? 'Désolé, une erreur est survenue. Veuillez réessayer.'
                  : 'Sorry, something went wrong. Please try again.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: _buildAppBar(isFr),
      body: Column(
        children: [
          // Gemini powered banner
          _GeminiPoweredBanner(isFr: isFr),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState(isFr: isFr)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildDisclaimerCard(isFr);
                      }
                      final msg = _messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),

          // Quick symptom chips (only when no messages beyond greeting)
          if (_messages.length <= 1 && !_isLoading)
            _QuickSymptomsRow(
              symptoms: isFr
                  ? ['Fièvre & frissons', 'Mal de tête', 'Toux & mal de gorge', 'Douleur abdominale', 'Fatigue']
                  : _quickSymptoms,
              onTap: _sendMessage,
            ),

          // Input area
          _buildInputBar(isFr),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isFr) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark, size: 20),
        onPressed: () => context.go('/home'),
      ),
      title: Row(
        children: [
          // PharmAI avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF0F9B8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Center(
              child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PharmAI',
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isFr ? 'En ligne · Assistant IA' : 'Online · AI Assistant',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 22),
          tooltip: isFr ? 'Nouvelle conversation' : 'New conversation',
          onPressed: () {
            setState(() {
              _messages.clear();
              _isLoading = false;
            });
            Future.delayed(const Duration(milliseconds: 200), () {
              if (!mounted) return;
              setState(() {
                _messages.add(
                  _ChatMessage(
                    id: 'greeting-${DateTime.now().millisecondsSinceEpoch}',
                    text: isFr
                        ? '👋 Bonjour ! Je suis **PharmAI**. *Comment puis-je vous aider aujourd\'hui ?*'
                        : '👋 Hello! I\'m **PharmAI**. *How can I help you today?*',
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            });
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    if (msg.isTyping) {
      return _TypingBubble(pulseAnimation: _pulseAnimation);
    }

    if (msg.isUser) {
      return _UserBubble(message: msg);
    }

    return _AiBubble(message: msg);
  }

  Widget _buildDisclaimerCard(bool isFr) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFE0FDF4)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isFr
                  ? 'PharmAI est un assistant IA à titre informatif uniquement. Il ne remplace pas un diagnostic médical professionnel. Consultez toujours un médecin ou pharmacien agréé.'
                  : 'PharmAI is an AI assistant for informational purposes only. It does not replace professional medical diagnosis. Always consult a licensed doctor or pharmacist.',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E40AF),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isFr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFFE),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isLoading
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
              ),
              child: TextField(
                controller: _textController,
                enabled: !_isLoading,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: isFr
                      ? 'Décrivez vos symptômes...'
                      : 'Describe your symptoms...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(isLoading: _isLoading, onTap: _sendMessage),
        ],
      ),
    );
  }
}

// ─── Sub-Widgets ─────────────────────────────────────────────────────────────

class _GeminiPoweredBanner extends StatelessWidget {
  final bool isFr;
  const _GeminiPoweredBanner({required this.isFr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0F9B8E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✦', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(width: 6),
          Text(
            isFr
                ? 'Propulsé par Gemini AI • Google DeepMind'
                : 'Powered by Gemini AI • Google DeepMind',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          const Text('✦', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFr;
  const _EmptyState({required this.isFr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF0F9B8E)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFr ? 'Chargement de PharmAI...' : 'Loading PharmAI...',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final Animation<double> pulseAnimation;
  const _TypingBubble({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PharmAIAvatar(),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, _) {
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.3, end: 1.0),
                        duration: Duration(milliseconds: 400 + i * 150),
                        curve: Curves.easeInOut,
                        builder: (context, value, _) {
                          return Opacity(
                            opacity: pulseAnimation.value,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                    alpha: 0.4 + (0.6 * pulseAnimation.value)),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final _ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF0F9B8E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
              fontSize: 13, color: Colors.white, height: 1.4),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final _ChatMessage message;
  const _AiBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PharmAIAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12, right: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: message.isStreaming
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textDark,
                            height: 1.45,
                          ),
                          strong: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                          em: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                          ),
                          listBullet: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                          blockquote: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (message.isStreaming) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Generating...',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmAIAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF0F9B8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}

class _QuickSymptomsRow extends StatelessWidget {
  final List<String> symptoms;
  final void Function(String) onTap;

  const _QuickSymptomsRow({required this.symptoms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: symptoms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final symptom = symptoms[index];
          return GestureDetector(
            onTap: () => onTap(symptom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                symptom,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _SendButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: isLoading
              ? const LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFFCBD5E1)])
              : const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF0F9B8E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          shape: BoxShape.circle,
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
