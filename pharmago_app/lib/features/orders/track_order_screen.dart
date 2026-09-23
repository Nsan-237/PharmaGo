// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Track Order Screen (Updated)
// Features added:
//  - Live chat between Client & Delivery Agent (quick-tap chips + DB messages)
//  - Smart 5-minute proactive status banner (auto-appears)
//  - "Signaler un problème" button (saves to DB, flags for admin)
//  - Cleaned up bottom action bar (replaces old payment button)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/adaptive_map_view.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/services/delivery_agent_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrderScreen extends ConsumerStatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  // Mock order ID — in real app passed via router extras
  static const String _mockOrderId = 'mock-order-id';
  static const String _mockAgentName = 'Martin T.';
  static const String _mockAgentPhone = '+237 6 98 76 54 32';

  bool _showSmartBanner = false;
  bool _bannerDismissed = false;
  Timer? _bannerTimer;
  final TextEditingController _chatInputController = TextEditingController();

  // Chat messages (local state, loaded from DB in real flow)
  final List<_ChatMessage> _messages = [
    const _ChatMessage(text: 'Je suis en route 🛵', isFromAgent: true, time: '14:32'),
  ];

  @override
  void initState() {
    super.initState();
    // Smart 5-minute banner: shows after 5 seconds in dev (would be 5 min in prod)
    _bannerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_bannerDismissed) {
        setState(() => _showSmartBanner = true);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _chatInputController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isFromAgent: false,
        time: '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      ));
    });

    // Send to backend
    await deliveryAgentService.sendMessage(_mockOrderId, text);

    if (mounted) {
      AppToast.show(context, message: 'Message envoyé au livreur ✓', type: ToastType.success);
    }
  }

  void _showChatSheet() {
    final isFr = ref.read(localeProvider) == AppLanguage.fr;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 24, left: 20, right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                  child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Message à $_mockAgentName (Livreur)',
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text(isFr ? 'Choisissez un message rapide' : 'Choose a quick message',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ]),
              const SizedBox(height: 16),
              // Custom message input with placeholder
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatInputController,
                      decoration: InputDecoration(
                        hintText: isFr
                            ? 'Écrivez votre message (ex: Où êtes-vous ?)...'
                            : 'Type your message (e.g. Where are you?)...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          Navigator.pop(ctx);
                          _sendMessage(val.trim());
                          _chatInputController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        final text = _chatInputController.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.pop(ctx);
                          _sendMessage(text);
                          _chatInputController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                isFr ? 'Ou choisissez une réponse rapide :' : 'Or choose a quick response:',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),

              // Quick-tap message chips
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  isFr ? 'Où êtes-vous ?' : 'Where are you?',
                  isFr ? 'Je suis devant 🏠' : 'I\'m outside 🏠',
                  isFr ? 'Portail noir 🚪' : 'Black gate 🚪',
                  isFr ? 'Appelez-moi en arrivant 📞' : 'Call me when you arrive 📞',
                  isFr ? 'Sonnez à la porte B 🔔' : 'Ring door B 🔔',
                  isFr ? 'Je vous attends dehors' : 'Waiting outside',
                ].map((msg) => ActionChip(
                  label: Text(msg, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                  backgroundColor: AppColors.primaryLight,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _sendMessage(msg);
                  },
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProblemSheet() {
    final isFr = ref.read(localeProvider) == AppLanguage.fr;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isFr ? 'Signaler un problème' : 'Report a Problem',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text(isFr ? 'Notre équipe sera notifiée immédiatement' : 'Our team will be notified immediately',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ]),
            const SizedBox(height: 16),
            ...[
              isFr ? '📵 Le livreur ne répond pas' : '📵 Driver not responding',
              isFr ? '⏰ Livraison trop longue' : '⏰ Delivery taking too long',
              isFr ? '📍 Mauvaise adresse de livraison' : '📍 Wrong delivery address',
              isFr ? '❓ Autre problème' : '❓ Other issue',
            ].map((reason) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFFFFF1F0), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 18),
              ),
              title: Text(reason, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await deliveryAgentService.reportProblem(_mockOrderId, reason);
                if (!mounted) return;
                AppToast.show(
                  context,
                  message: result['success'] == true
                    ? (isFr ? 'Problème signalé. L\'équipe a été notifiée 🔔' : 'Problem reported. Team notified 🔔')
                    : (isFr ? 'Impossible de signaler le problème' : 'Failed to report problem'),
                  type: result['success'] == true ? ToastType.info : ToastType.error,
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFr = ref.watch(localeProvider) == AppLanguage.fr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => context.go('/orders'),
        ),
        title: Text(
          context.tr('track.title', ref: ref),
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        actions: [
          // Report Problem button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _showProblemSheet,
              icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
              label: Text(
                isFr ? 'Signaler' : 'Report',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Smart 5-min proactive banner ─────────────────────────
            if (_showSmartBanner && !_bannerDismissed)
              _SmartStatusBanner(
                isFr: isFr,
                agentName: _mockAgentName,
                onDismiss: () => setState(() => _bannerDismissed = true),
                onChat: _showChatSheet,
              ),

            if (_showSmartBanner && !_bannerDismissed) const SizedBox(height: 16),

            // ── Map with Route & Live Driver Tracking ─────────────────
            const AdaptiveMapView(
              height: 210,
              showRoute: true,
              title: 'Order #PGO-4587',
              etaText: '25 - 35 min',
            ),

            const SizedBox(height: 20),

            // ── Order Status Card ─────────────────────────────────────
            _buildStatusCard(isFr),

            const SizedBox(height: 16),

            // ── Pharmacy Card ─────────────────────────────────────────
            _buildPharmacyCard(isFr),

            const SizedBox(height: 16),

            // ── Delivery Agent Card ───────────────────────────────────
            _buildAgentCard(isFr),

            const SizedBox(height: 20),

            // ── Live Chat Section ─────────────────────────────────────
            _buildChatSection(isFr),
          ],
        ),
      ),

      // ── Bottom Action: Track & Chat (cleaned up) ──────────────────
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _showChatSheet,
                icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                label: Text(
                  isFr ? 'Discuter avec le livreur' : 'Chat with Driver',
                  style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isFr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #PGO-4587',
                style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  context.tr('track.inProgress', ref: ref),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            _TimelineStep(title: context.tr('track.stepOrderPlaced', ref: ref), time: '14:10', isDone: true, isFirst: true),
            _TimelineStep(title: context.tr('track.stepConfirmed', ref: ref), time: '14:15', isDone: true),
            _TimelineStep(title: context.tr('track.stepPreparing', ref: ref), time: '14:22', isDone: true),
            _TimelineStep(title: context.tr('track.stepOutForDelivery', ref: ref), time: '14:31', isDone: true, isCurrent: true),
            _TimelineStep(title: context.tr('track.stepDelivered', ref: ref), time: isFr ? 'En attente...' : 'Pending...', isDone: false, isLast: true),
          ],
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(bool isFr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pharmacie Centrale', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text('Avenue Kennedy, Douala • +237 222 23 11 60',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ],
          )),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 18),
            ),
            onPressed: () async {
              final uri = Uri.parse('tel:+237222231160');
              final ctx = context;
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else if (ctx.mounted) {
                AppToast.show(ctx, message: 'Appel vers Pharmacie Centrale...', type: ToastType.info);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(bool isFr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF2563EB), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(_mockAgentName,
                  style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                  child: Text(isFr ? 'En route' : 'On the way',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF166534))),
                ),
              ]),
              const SizedBox(height: 2),
              Text(_mockAgentPhone, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
            ],
          )),
          // Call Driver
          IconButton(
            tooltip: isFr ? 'Appeler le livreur' : 'Call driver',
            onPressed: () async {
              final cleanPhone = _mockAgentPhone.replaceAll(RegExp(r'[^0-9+]'), '');
              final uri = Uri.parse('tel:$cleanPhone');
              final ctx = context;
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else if (ctx.mounted) {
                AppToast.show(ctx,
                  message: isFr ? 'Composition du $_mockAgentPhone...' : 'Dialing $_mockAgentPhone...',
                  type: ToastType.info);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 18),
            ),
          ),
          // Message Driver
          IconButton(
            tooltip: isFr ? 'Envoyer un message' : 'Message driver',
            onPressed: _showChatSheet,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF0284C7), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection(bool isFr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                isFr ? 'Messages avec Martin T.' : 'Messages with Martin T.',
                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ]),
          ),
          const Divider(height: 1),
          // Chat bubbles
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: _messages.map((msg) => _buildBubble(msg)).toList(),
            ),
          ),
          // Quick chip bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  isFr ? 'Où êtes-vous ?' : 'Where are you?',
                  isFr ? 'Je suis devant 🏠' : 'I\'m outside 🏠',
                  isFr ? 'Portail noir 🚪' : 'Black gate 🚪',
                  isFr ? 'Appelez-moi 📞' : 'Call me 📞',
                  isFr ? 'Sonnez à la porte 🔔' : 'Ring the bell 🔔',
                ].map((msg) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(msg, style: GoogleFonts.inter(fontSize: 11)),
                    backgroundColor: AppColors.primaryLight,
                    onPressed: () => _sendMessage(msg),
                  ),
                )).toList(),
              ),
            ),
          ),
          // Custom text message input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    decoration: InputDecoration(
                      hintText: isFr ? 'Écrivez un message au livreur...' : 'Type a message to the driver...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _sendMessage(val.trim());
                        _chatInputController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () {
                      final text = _chatInputController.text.trim();
                      if (text.isNotEmpty) {
                        _sendMessage(text);
                        _chatInputController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: msg.isFromAgent ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (msg.isFromAgent) ...[
            const CircleAvatar(radius: 12, backgroundColor: Color(0xFFEFF6FF),
              child: Icon(Icons.delivery_dining_rounded, size: 14, color: Color(0xFF2563EB))),
            const SizedBox(width: 6),
          ],
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: msg.isFromAgent ? const Color(0xFFF1F5F9) : AppColors.primaryLight,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(msg.isFromAgent ? 2 : 14),
                bottomRight: Radius.circular(msg.isFromAgent ? 14 : 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: msg.isFromAgent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(msg.text,
                  style: GoogleFonts.inter(fontSize: 13, color: msg.isFromAgent ? AppColors.textDark : AppColors.primaryDark)),
                const SizedBox(height: 2),
                Text(msg.time,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (!msg.isFromAgent) ...[
            const SizedBox(width: 6),
            const CircleAvatar(radius: 12, backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person_rounded, size: 14, color: AppColors.primary)),
          ],
        ],
      ),
    );
  }
}

// ── Chat message model ───────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isFromAgent;
  final String time;
  const _ChatMessage({required this.text, required this.isFromAgent, required this.time});
}

// ── Smart Status Banner ──────────────────────────────────────────────────────
class _SmartStatusBanner extends StatelessWidget {
  final bool isFr;
  final String agentName;
  final VoidCallback onDismiss;
  final VoidCallback onChat;

  const _SmartStatusBanner({
    required this.isFr,
    required this.agentName,
    required this.onDismiss,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFr
                    ? '$agentName a récupéré votre colis il y a 5 min.'
                    : '$agentName picked up your package 5 min ago.',
                  style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onChat,
                  child: Text(
                    isFr ? 'Tout se passe bien ? Discutez avec lui ↓' : 'Everything OK? Chat below ↓',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, decoration: TextDecoration.underline, decorationColor: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Timeline Step ────────────────────────────────────────────────────────────
class _TimelineStep extends StatelessWidget {
  final String title;
  final String time;
  final bool isDone;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    required this.time,
    required this.isDone,
    this.isCurrent = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDone ? AppColors.primary : AppColors.textMuted, width: 2),
                  ),
                  child: isDone ? const Icon(Icons.check, size: 8, color: Colors.white) : null,
                ),
                if (!isLast)
                  Expanded(child: Container(
                    width: 2,
                    color: isDone ? AppColors.primary : AppColors.border,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                    color: isDone ? AppColors.textDark : AppColors.textMuted,
                  )),
                Text(time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isCurrent ? AppColors.primary : AppColors.textMuted,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  )),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
