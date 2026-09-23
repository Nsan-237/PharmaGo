import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/widgets/app_toast.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;
    final ordersList = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          context.tr('orders.title', ref: ref),
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: context.tr('orders.tabAll', ref: ref)),
            Tab(text: context.tr('orders.tabOngoing', ref: ref)),
            Tab(text: context.tr('orders.tabCompleted', ref: ref)),
            Tab(text: context.tr('orders.tabCancelled', ref: ref)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All
          _buildOrdersList(ordersList, isFr),
          // Ongoing
          _buildOrdersList(
            ordersList.where((o) => o.status == 'in_progress' || o.status == 'en_attente').toList(),
            isFr,
          ),
          // Completed
          _buildOrdersList(
            ordersList.where((o) => o.status == 'completed' || o.status == 'livree').toList(),
            isFr,
          ),
          // Cancelled
          _buildOrdersList(
            ordersList.where((o) => o.status == 'cancelled').toList(),
            isFr,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<ClientOrderModel> orders, bool isFr) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              isFr ? 'Aucune commande' : 'No orders found',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderListItem(order: order, isFr: isFr);
      },
    );
  }
}

class _OrderListItem extends ConsumerWidget {
  final ClientOrderModel order;
  final bool isFr;

  const _OrderListItem({required this.order, required this.isFr});

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isFr ? 'Annuler la commande ?' : 'Cancel this order?',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: Text(
          isFr
              ? 'Cette action est irréversible. La commande ${order.id} sera annulée.'
              : 'This action is irreversible. Order ${order.id} will be cancelled.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isFr ? 'Non, garder' : 'Keep it',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isFr ? 'Oui, annuler' : 'Yes, cancel',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(ordersProvider.notifier).cancelOrder(order.id);
      if (context.mounted) {
        AppToast.show(
          context,
          message: isFr ? 'Commande ${order.id} annulée.' : 'Order ${order.id} cancelled.',
          type: ToastType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInProgress = order.status == 'in_progress' || order.status == 'en_attente';
    final isDelivered = order.status == 'completed' || order.status == 'livree';

    Color badgeBg;
    Color badgeText;
    String statusLabel;

    if (isInProgress) {
      badgeBg   = AppColors.primaryLight;
      badgeText = AppColors.primary;
      statusLabel = isFr ? 'En cours' : 'In Progress';
    } else if (isDelivered) {
      badgeBg   = AppColors.successLight;
      badgeText = AppColors.success;
      statusLabel = isFr ? 'Livrée' : 'Delivered';
    } else {
      badgeBg   = AppColors.errorLight;
      badgeText = AppColors.error;
      statusLabel = isFr ? 'Annulée' : 'Cancelled';
    }

    return GestureDetector(
      onTap: isInProgress ? () => context.go('/track-order') : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Order Icon Box
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isInProgress
                    ? Icons.local_shipping_outlined
                    : (isDelivered ? Icons.task_alt_rounded : Icons.cancel_outlined),
                color: badgeText,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Order Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.drugs.join(', '),
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.createdAt,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            // Status Badge & ETA
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: badgeText),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.estimatedTime,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isInProgress ? FontWeight.bold : FontWeight.normal,
                    color: isInProgress ? AppColors.primaryDark : AppColors.textMuted,
                  ),
                ),
                // Cancel button — only for pending/in-progress orders
                if (isInProgress) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _confirmCancel(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isFr ? 'Annuler' : 'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
