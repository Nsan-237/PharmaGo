// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Delivery Agent Screen
// Full mobile dashboard for DELIVERY_AGENT role
// Features: online/offline toggle, earnings bar, 3 tabs (assigned/en route/done),
// payment badges, call/WhatsApp/GPS shortcuts, live chat, delay reporting,
// bilingual French & English localization
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/delivery_agent_service.dart';
import '../../core/widgets/app_toast.dart';

// ── State classes ────────────────────────────────────────────────────────────

class _AgentStats {
  final int deliveriesToday;
  final int earningsToday;
  final int cashInHand;
  _AgentStats({
    this.deliveriesToday = 0,
    this.earningsToday = 0,
    this.cashInHand = 0,
  });
}

// ── Main Screen ──────────────────────────────────────────────────────────────

class DeliveryAgentScreen extends ConsumerStatefulWidget {
  const DeliveryAgentScreen({super.key});

  @override
  ConsumerState<DeliveryAgentScreen> createState() => _DeliveryAgentScreenState();
}

class _DeliveryAgentScreenState extends ConsumerState<DeliveryAgentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = true;
  bool _isLoading = true;
  _AgentStats _stats = _AgentStats(deliveriesToday: 4, earningsToday: 4000, cashInHand: 7500);
  List<Map<String, dynamic>> _availableOrders = [];
  List<Map<String, dynamic>> _inTransitOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ordersResult = await deliveryAgentService.getOrders();
    final statsResult = await deliveryAgentService.getStats();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (ordersResult['success'] == true) {
        final data = ordersResult['data'] as Map<String, dynamic>;
        _availableOrders = List<Map<String, dynamic>>.from(data['available'] ?? []);
        _inTransitOrders = List<Map<String, dynamic>>.from(data['assigned'] ?? []);
        _deliveredOrders = List<Map<String, dynamic>>.from(data['delivered'] ?? []);
      }
      if (statsResult['success'] == true) {
        final s = statsResult['data'] as Map<String, dynamic>;
        _stats = _AgentStats(
          deliveriesToday: s['deliveriesToday'] ?? _stats.deliveriesToday,
          earningsToday: s['earningsToday'] ?? _stats.earningsToday,
          cashInHand: s['cashInHand'] ?? _stats.cashInHand,
        );
      }
    });
  }

  Future<void> _toggleOnline(bool val, bool isFr) async {
    setState(() => _isOnline = val);
    await deliveryAgentService.setAvailability(val);
    if (!mounted) return;
    AppToast.show(
      context,
      message: val
          ? (isFr ? 'Vous êtes en ligne — Prêt à livrer 🟢' : 'You are online — Ready to deliver 🟢')
          : (isFr ? 'Vous êtes hors ligne — En pause ⏸' : 'You are offline — On a break ⏸'),
      type: ToastType.info,
    );
  }

  Future<void> _acceptOrder(Map<String, dynamic> order, bool isFr) async {
    final result = await deliveryAgentService.acceptOrder(order['id'] ?? order['orderNumber']);
    if (!mounted) return;
    if (result['success'] == true) {
      AppToast.show(
        context,
        message: isFr
            ? 'Commande acceptée — Allez à la pharmacie ! 🛵'
            : 'Order accepted — Head to the pharmacy! 🛵',
        type: ToastType.success,
      );
      _loadData();
      _tabController.animateTo(1);
    } else {
      AppToast.show(
        context,
        message: result['error'] ?? (isFr ? 'Erreur' : 'Error'),
        type: ToastType.error,
      );
    }
  }

  Future<void> _markDelivered(Map<String, dynamic> order, bool isFr) async {
    final paymentMethod = order['paymentMethod'] ?? 'CASH';
    final amount = (order['totalAmount'] ?? 0).toDouble();
    final isMomo = paymentMethod != 'CASH';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(isMomo ? Icons.mobile_friendly_rounded : Icons.payments_rounded,
              color: isMomo ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            isFr ? 'Confirmer la livraison' : 'Confirm Delivery',
            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
          )),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMomo ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMomo ? const Color(0xFF86EFAC) : const Color(0xFFFBD38D)),
              ),
              child: Column(
                children: [
                  Icon(
                    isMomo ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: isMomo ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMomo
                        ? (isFr
                            ? 'Déjà payé par Mobile Money\nNE RIEN ENCAISSER chez le client'
                            : 'Already paid via Mobile Money\nDO NOT COLLECT CASH from customer')
                        : (isFr
                            ? 'Encaisser chez le client :\n${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA'
                            : 'Collect from customer:\n${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isMomo ? const Color(0xFF166534) : const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isFr ? '✅ Livré !' : '✅ Delivered!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await deliveryAgentService.markDelivered(order['id'] ?? order['orderNumber']);
      if (!mounted) return;
      if (result['success'] == true) {
        AppToast.show(
          context,
          message: isFr ? 'Livraison confirmée ! Bravo 🎉' : 'Delivery confirmed! Great job 🎉',
          type: ToastType.success,
        );
        _loadData();
        _tabController.animateTo(2);
      } else {
        AppToast.show(
          context,
          message: result['error'] ?? (isFr ? 'Erreur' : 'Error'),
          type: ToastType.error,
        );
      }
    }
  }

  void _openGps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _callNumber(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _whatsApp(String phone, String orderNumber, bool isFr) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final msgText = isFr
        ? 'Bonjour ! Je suis votre livreur PharmaGo pour la commande $orderNumber. Je suis en route vers vous.'
        : 'Hello! I am your PharmaGo delivery driver for order $orderNumber. I am on my way to you.';
    final msg = Uri.encodeComponent(msgText);
    final url = Uri.parse('https://wa.me/$cleaned?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showDelaySheet(Map<String, dynamic> order, bool isFr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isFr ? 'Signaler un retard' : 'Report a Delay',
                style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(isFr ? 'Choisissez la raison du retard' : 'Choose delay reason',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ...(isFr
              ? ['🚗 Embouteillage / Traffic', '📵 Client injoignable', '🗺️ Difficulté à trouver l\'adresse', '🔧 Problème mécanique']
              : ['🚗 Heavy Traffic / Traffic jam', '📵 Customer unreachable', '🗺️ Difficulty finding address', '🔧 Mechanical issue']
            ).map(
              (reason) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(reason, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await deliveryAgentService.reportDelay(order['id'] ?? order['orderNumber'], reason);
                  if (!mounted) return;
                  AppToast.show(context,
                    message: result['success'] == true
                        ? (isFr ? 'Retard signalé ✓' : 'Delay reported ✓')
                        : (isFr ? 'Erreur lors du signalement' : 'Failed to report delay'),
                    type: result['success'] == true ? ToastType.info : ToastType.error);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatSheet(Map<String, dynamic> order, bool isFr) {
    final patientName = (order['patient'] as Map?)?['fullName'] ?? (isFr ? 'le client' : 'Customer');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 24, left: 20, right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFr ? 'Message à $patientName' : 'Message to $patientName',
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(isFr ? 'Tapez un message rapide :' : 'Choose a quick message:',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (isFr
                ? [
                    'Je suis en route 🛵',
                    'Je suis au carrefour 📍',
                    'Je suis devant votre portail 🚪',
                    'J\'arrive dans 5 min ⏱️',
                    'Pouvez-vous m\'appeler ? 📞',
                  ]
                : [
                    'I am on my way 🛵',
                    'I am at the junction 📍',
                    'I am outside your gate 🚪',
                    'Arriving in 5 min ⏱️',
                    'Can you call me? 📞',
                  ]
              ).map((msg) => ActionChip(
                label: Text(msg, style: GoogleFonts.inter(fontSize: 12)),
                backgroundColor: AppColors.primaryLight,
                onPressed: () async {
                  Navigator.pop(ctx);
                  final result = await deliveryAgentService.sendMessage(order['id'] ?? order['orderNumber'], msg);
                  if (!mounted) return;
                  AppToast.show(context,
                    message: result['success'] == true
                        ? (isFr ? 'Message envoyé ✓' : 'Message sent ✓')
                        : (isFr ? 'Erreur' : 'Error'),
                    type: result['success'] == true ? ToastType.success : ToastType.error);
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build methods ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;
    final authState = ref.watch(authProvider);
    final agentName = authState.fullName.isNotEmpty ? authState.fullName : 'Eric Mben';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agentName,
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isFr ? 'Livreur PharmaGo 🛵' : 'PharmaGo Delivery Agent 🛵',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // Online / Offline Toggle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isOnline ? (isFr ? 'En ligne' : 'Online') : (isFr ? 'Hors ligne' : 'Offline'),
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: _isOnline ? const Color(0xFF16A34A) : AppColors.textMuted,
                  ),
                ),
                Switch(
                  value: _isOnline,
                  activeThumbColor: const Color(0xFF16A34A),
                  activeTrackColor: const Color(0xFFDCFCE7),
                  inactiveThumbColor: Colors.grey,
                  onChanged: (val) => _toggleOnline(val, isFr),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Language Switch Button
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ActionChip(
              avatar: Text(isFr ? '🇫🇷' : '🇬🇧', style: const TextStyle(fontSize: 13)),
              label: Text(
                isFr ? 'FR' : 'EN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              onPressed: () => ref.read(localeProvider.notifier).toggleLanguage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textDark, size: 20),
            tooltip: isFr ? 'Déconnexion' : 'Log out',
            onPressed: () async {
              final router = GoRouter.of(context);
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              router.go('/login');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: Column(
                children: [
                  // ── Daily Earnings Bar ─────────────────────────────────
                  _buildEarningsBar(isFr),

                  // ── Tabs ──────────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.primary,
                      labelStyle: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold),
                      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                      tabs: [
                        Tab(text: isFr ? 'Assignées (${_availableOrders.length})' : 'Assigned (${_availableOrders.length})'),
                        Tab(text: isFr ? 'En route (${_inTransitOrders.length})' : 'In Transit (${_inTransitOrders.length})'),
                        Tab(text: isFr ? 'Livrées (${_deliveredOrders.length})' : 'Delivered (${_deliveredOrders.length})'),
                      ],
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrderList(_availableOrders, 'available', isFr),
                        _buildOrderList(_inTransitOrders, 'in_transit', isFr),
                        _buildOrderList(_deliveredOrders, 'delivered', isFr),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEarningsBar(bool isFr) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B36), Color(0xFF0F9B8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.local_shipping_rounded, '${_stats.deliveriesToday}', isFr ? 'Courses' : 'Deliveries'),
          _divider(),
          _statItem(Icons.account_balance_wallet_rounded,
            '${_stats.earningsToday.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA',
            isFr ? 'Gains' : 'Earnings'),
          _divider(),
          _statItem(Icons.payments_rounded,
            '${_stats.cashInHand.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA',
            isFr ? 'Cash en main' : 'Cash in Hand'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white24);

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String type, bool isFr) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == 'available' ? Icons.inbox_rounded : type == 'in_transit' ? Icons.directions_bike_rounded : Icons.check_circle_outline_rounded,
              size: 56, color: AppColors.border,
            ),
            const SizedBox(height: 12),
            Text(
              type == 'available'
                  ? (isFr ? 'Aucune commande disponible' : 'No available orders')
                  : type == 'in_transit'
                      ? (isFr ? 'Aucune livraison en cours' : 'No deliveries in progress')
                      : (isFr ? 'Aucune livraison aujourd\'hui' : 'No deliveries today'),
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
            ),
            if (type == 'available') ...[
              const SizedBox(height: 8),
              Text(isFr ? 'Revenez plus tard 🕐' : 'Check back later 🕐',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: orders.length,
      itemBuilder: (context, i) => _buildOrderCard(orders[i], type, isFr),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String type, bool isFr) {
    final patient = order['patient'] as Map<String, dynamic>?;
    final pharmacy = order['pharmacy'] as Map<String, dynamic>?;
    final items = (order['items'] as List<dynamic>? ?? []);
    final paymentMethod = order['paymentMethod'] ?? 'CASH';
    final totalAmount = (order['totalAmount'] ?? 0).toDouble();
    final isMomo = paymentMethod != 'CASH';
    final orderNumber = order['orderNumber'] ?? '#---';
    final deliveryAddress = order['deliveryAddress'] ?? '';
    final clientPhone = patient?['phone'] ?? '';
    final pharmacyPhone = pharmacy?['phone'] ?? '';
    final pharmacyAddress = pharmacy?['address'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // ── Card Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(orderNumber, style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text(order['id']?.toString().substring(0, 8) ?? '', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                ]),
                // Payment Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isMomo ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isMomo ? const Color(0xFF86EFAC) : const Color(0xFFFBD38D)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isMomo ? Icons.mobile_friendly_rounded : Icons.payments_rounded,
                        size: 12, color: isMomo ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      isMomo
                          ? (isFr ? 'Déjà payé (MoMo)' : 'Prepaid (MoMo)')
                          : 'Cash: ${totalAmount.toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: isMomo ? const Color(0xFF166534) : const Color(0xFF92400E),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          const Divider(height: 20, indent: 16, endIndent: 16),

          // ── Details ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Client row
                _infoRow(
                  Icons.person_rounded,
                  isFr ? 'Client' : 'Customer',
                  patient?['fullName'] ?? (isFr ? 'Inconnu' : 'Unknown'),
                ),
                const SizedBox(height: 8),
                // Address row
                _infoRow(
                  Icons.location_on_rounded,
                  isFr ? 'Adresse' : 'Address',
                  deliveryAddress.isEmpty ? (isFr ? 'Non précisée' : 'Not specified') : deliveryAddress,
                ),
                const SizedBox(height: 8),
                // Pharmacy row
                _infoRow(
                  Icons.local_pharmacy_rounded,
                  isFr ? 'Pharmacie' : 'Pharmacy',
                  pharmacy?['name'] ?? (isFr ? 'Inconnue' : 'Unknown'),
                ),
                if (pharmacyAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(pharmacyAddress, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ),
                ],
                const SizedBox(height: 8),
                // Medications
                _infoRow(
                  Icons.medication_rounded,
                  isFr ? 'Médicaments' : 'Medications',
                  items.isEmpty
                      ? (isFr ? 'Voir détails' : 'View details')
                      : items.take(3).map((item) => '${item['productName']} ×${item['quantity']}').join(', '),
                ),
              ],
            ),
          ),

          // ── Action Buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                // Call Client
                if (clientPhone.isNotEmpty)
                  _iconBtn(Icons.phone_rounded, const Color(0xFF2563EB), () => _callNumber(clientPhone), isFr ? 'Appeler client' : 'Call customer'),
                // WhatsApp Client
                if (clientPhone.isNotEmpty)
                  _iconBtn(Icons.chat_rounded, const Color(0xFF16A34A), () => _whatsApp(clientPhone, orderNumber, isFr), 'WhatsApp'),
                // Call Pharmacy
                if (pharmacyPhone.isNotEmpty)
                  _iconBtn(Icons.local_pharmacy_rounded, AppColors.primary, () => _callNumber(pharmacyPhone), isFr ? 'Pharmacie' : 'Pharmacy'),
                // GPS
                if (type == 'available')
                  _iconBtn(Icons.navigation_rounded, const Color(0xFFD97706), () => _openGps(pharmacyAddress.isNotEmpty ? pharmacyAddress : deliveryAddress), isFr ? 'GPS Pharmacie' : 'GPS Pharmacy'),
                if (type == 'in_transit')
                  _iconBtn(Icons.navigation_rounded, const Color(0xFFD97706), () => _openGps(deliveryAddress), isFr ? 'GPS Client' : 'GPS Customer'),
                // Chat (in transit only)
                if (type == 'in_transit')
                  _iconBtn(Icons.chat_bubble_rounded, const Color(0xFF7C3AED), () => _showChatSheet(order, isFr), isFr ? 'Message' : 'Message'),
                const Spacer(),
                // Delay report (in transit only)
                if (type == 'in_transit')
                  TextButton(
                    onPressed: () => _showDelaySheet(order, isFr),
                    child: Text(
                      isFr ? '⚠️ Retard' : '⚠️ Delay',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFD97706), fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // ── Primary Action Button ─────────────────────────────────────
          if (type != 'delivered')
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == 'available' ? AppColors.primary : const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => type == 'available' ? _acceptOrder(order, isFr) : _markDelivered(order, isFr),
                  child: Text(
                    type == 'available'
                        ? (isFr ? '✅ Accepter & Partir en livraison' : '✅ Accept & Start Delivery')
                        : (isFr ? '📦 Marquer comme Livré' : '📦 Mark as Delivered'),
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    isFr ? 'Livraison complétée' : 'Delivery completed',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF16A34A), fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${totalAmount.toStringAsFixed(0)} FCFA',
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '$label : ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              TextSpan(text: value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
