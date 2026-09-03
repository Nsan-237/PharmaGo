import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
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
  final Uint8List? imageBytes;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
    this.isStreaming = false,
    this.imageBytes,
  });

  _ChatMessage copyWith({String? text, bool? isTyping, bool? isStreaming}) {
    return _ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      isTyping: isTyping ?? this.isTyping,
      isStreaming: isStreaming ?? this.isStreaming,
      imageBytes: imageBytes,
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
  final ImagePicker _imagePicker = ImagePicker();
  final List<_ChatMessage> _messages = [];

  bool _isLoading = false;
  Uint8List? _pendingImageBytes;
  String? _pendingImageMime;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _quickSymptomsEn = [
    'Fever & chills',
    'Headache',
    'Cough & sore throat',
    'Stomach pain',
    'Fatigue',
  ];

  final List<String> _quickSymptomsFr = [
    'Fièvre & frissons',
    'Mal de tête',
    'Toux & mal de gorge',
    'Douleur abdominale',
    'Fatigue',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Greeting from PharmAI
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final isFr = ref.read(localeProvider) == AppLanguage.fr;
      setState(() {
        _messages.add(
          _ChatMessage(
            id: 'greeting',
            text: isFr
                ? '👋 Bonjour ! Je suis **PharmAI**, votre assistant médical intelligent propulsé par Gemini AI.\n\nDécrivez vos symptômes en texte ou **envoyez une photo** (rougeur, plaie, médicament…) et je vous aiderai.\n\n*Comment puis-je vous aider aujourd\'hui ?*'
                : '👋 Hello! I\'m **PharmAI**, your intelligent medical assistant powered by Gemini AI.\n\nDescribe your symptoms in text or **send a photo** (rash, wound, medication label…) and I\'ll help you understand what\'s happening.\n\n*How can I help you today?*',
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

  // ─── Image Picker ────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile == null) return;
      final bytes = await xFile.readAsBytes();
      final mime = xFile.mimeType ?? 'image/jpeg';
      setState(() {
        _pendingImageBytes = bytes;
        _pendingImageMime = mime;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet(bool isFr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFr ? 'Envoyer une image' : 'Send an image',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isFr
                    ? 'PharmAI analysera votre image médicalement'
                    : 'PharmAI will analyze your image medically',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: isFr ? 'Caméra' : 'Camera',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: isFr ? 'Galerie' : 'Gallery',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Send Message ─────────────────────────────────────────────────────────

  Future<void> _sendMessage([String? quickMessage]) async {
    final text = (quickMessage ?? _textController.text).trim();
    final imageBytes = _pendingImageBytes;
    final imageMime = _pendingImageMime;

    if (text.isEmpty && imageBytes == null) return;
    if (_isLoading) return;

    // Add user message (with optional image)
    final userMsg = _ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
    );

    final typingMsgId = 'typing-${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _messages.add(userMsg);
      if (quickMessage == null) _textController.clear();
      _pendingImageBytes = null;
      _pendingImageMime = null;
      _isLoading = true;
      _messages.add(
        _ChatMessage(
          id: typingMsgId,
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: true,
        ),
      );
    });

    _scrollToBottom();

    try {
      final streamId = 'ai-${DateTime.now().millisecondsSinceEpoch}';
      String accumulated = '';
      bool replacedTyping = false;

      final stream = GeminiService.streamSymptomAnalysis(
        text,
        imageBytes: imageBytes,
        imageMimeType: imageMime,
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        accumulated += chunk;

        setState(() {
          if (!replacedTyping) {
            final idx = _messages.indexWhere((m) => m.id == typingMsgId);
            if (idx != -1) {
              _messages[idx] = _ChatMessage(
                id: streamId,
                text: accumulated,
                isUser: false,
                timestamp: DateTime.now(),
                isStreaming: true,
              );
            }
            replacedTyping = true;
          } else {
            final idx = _messages.indexWhere((m) => m.id == streamId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(text: accumulated);
            }
          }
        });

        _scrollToBottom();
      }

      // Finalize
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere(
              (m) => m.id == streamId || m.id == typingMsgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              text: accumulated,
              isStreaming: false,
              isTyping: false,
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == typingMsgId);
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: _buildAppBar(isFr),
      body: Column(
        children: [
          _GeminiStatusBanner(isFr: isFr),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + 1,
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildDisclaimerCard(isFr);
                }
                return _buildBubble(_messages[index], isFr);
              },
            ),
          ),

          // Quick symptom chips (only on first load)
          if (_messages.length <= 1 && !_isLoading)
            _QuickSymptomsRow(
              symptoms: isFr ? _quickSymptomsFr : _quickSymptomsEn,
              onTap: _sendMessage,
            ),

          // Pending image preview
          if (_pendingImageBytes != null)
            _PendingImagePreview(
              imageBytes: _pendingImageBytes!,
              onRemove: () => setState(() {
                _pendingImageBytes = null;
                _pendingImageMime = null;
              }),
            ),

          _buildInputBar(isFr),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isFr) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark, size: 20),
        onPressed: () => context.go('/home'),
      ),
      title: Row(
        children: [
          // PharmAI Gemini avatar
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
                ),
              ],
            ),
            child: const Center(
              child: Text('✦',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
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
                    GeminiService.isUsingRealApi
                        ? (isFr ? 'Gemini AI · En ligne' : 'Gemini AI · Live')
                        : (isFr ? 'Mode démo' : 'Demo mode'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: GeminiService.isUsingRealApi
                          ? AppColors.success
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Reset chat
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              color: AppColors.textMuted, size: 22),
          tooltip: isFr ? 'Nouvelle conversation' : 'New conversation',
          onPressed: () {
            setState(() {
              _messages.clear();
              _pendingImageBytes = null;
              _isLoading = false;
            });
            Future.delayed(const Duration(milliseconds: 200), () {
              if (!mounted) return;
              setState(() {
                _messages.add(
                  _ChatMessage(
                    id: 'greeting-new',
                    text: isFr
                        ? '👋 Nouvelle session. Comment puis-je vous aider ?'
                        : '👋 New session. How can I help you today?',
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

  Widget _buildBubble(_ChatMessage msg, bool isFr) {
    if (msg.isTyping) {
      return _TypingBubble(pulseAnimation: _pulseAnimation);
    }
    if (msg.isUser) return _UserBubble(message: msg);
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
                  ? 'PharmAI est un assistant IA à titre informatif uniquement. Il ne remplace pas un diagnostic médical professionnel.'
                  : 'PharmAI is an AI assistant for informational purposes only. It does not replace professional medical diagnosis.',
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image attach button
          GestureDetector(
            onTap: () => _showImageSourceSheet(isFr),
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _pendingImageBytes != null
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _pendingImageBytes != null
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 20,
                color: _pendingImageBytes != null
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ),

          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFFE),
                borderRadius: BorderRadius.circular(22),
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
                maxLines: 4,
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

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _GeminiStatusBanner extends StatelessWidget {
  final bool isFr;
  const _GeminiStatusBanner({required this.isFr});

  @override
  Widget build(BuildContext context) {
    final isLive = GeminiService.isUsingRealApi;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [const Color(0xFF1A73E8), const Color(0xFF0F9B8E)]
              : [const Color(0xFF64748B), const Color(0xFF94A3B8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLive ? Icons.bolt_rounded : Icons.info_outline_rounded,
            color: Colors.white,
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            isLive
                ? (isFr
                    ? 'Propulsé par Gemini AI · Google DeepMind · IA en direct'
                    : 'Powered by Gemini AI · Google DeepMind · Live AI')
                : (isFr ? 'Mode démo — réponses prédéfinies' : 'Demo mode — predefined responses'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingImagePreview extends StatelessWidget {
  final Uint8List imageBytes;
  final VoidCallback onRemove;

  const _PendingImagePreview(
      {required this.imageBytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: Colors.white,
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  imageBytes,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image ready to send',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'PharmAI will analyze it with Gemini Vision',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome_rounded,
              color: AppColors.primary, size: 18),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: (0.3 + 0.7 *
                                  ((pulseAnimation.value + i * 0.33) % 1.0))
                              .clamp(0.3, 1.0),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image preview if user sent image
            if (message.imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  message.imageBytes!,
                  width: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (message.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
          ],
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
            child: Container(
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
                      ? AppColors.primary.withValues(alpha: 0.4)
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
                          height: 1.45),
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
                          fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                  if (message.isStreaming) ...[
                    const SizedBox(height: 8),
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
                          'Gemini is generating...',
                          style: GoogleFonts.inter(
                              fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
        child: Text('✦',
            style: TextStyle(color: Colors.white, fontSize: 13)),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: symptoms.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => onTap(symptoms[index]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  symptoms[index],
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
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
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
              ? const LinearGradient(
                  colors: [Color(0xFFCBD5E1), Color(0xFFCBD5E1)])
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
