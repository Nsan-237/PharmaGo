import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/app_toast.dart';

class RequestOrderScreen extends ConsumerStatefulWidget {
  const RequestOrderScreen({super.key});

  @override
  ConsumerState<RequestOrderScreen> createState() => _RequestOrderScreenState();
}

class _RequestOrderScreenState extends ConsumerState<RequestOrderScreen> {
  int _quantity = 1;
  bool _hasUploadedRx = true;
  String _deliveryOption = 'home'; // 'pickup' or 'home'

  final int _unitPrice = 1200;
  final int _deliveryFee = 1000;

  int get _totalPrice {
    final subtotal = _unitPrice * _quantity;
    return _deliveryOption == 'home' ? subtotal + _deliveryFee : subtotal;
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => context.go('/pharmacy-details'),
        ),
        title: Text(
          context.tr('order.requestTitle', ref: ref),
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Selected Drug Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication_liquid_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amoxicillin 500mg',
                          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1 200 FCFA',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. Quantity Selector ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('order.quantity', ref: ref),
                  style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_quantity',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _quantity++),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 3. Upload Prescription (Optional) ──
            Text(
              context.tr('order.uploadRxOptional', ref: ref),
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),

            // Upload Box / File Chip
            if (!_hasUploadedRx)
              GestureDetector(
                onTap: () {
                  setState(() => _hasUploadedRx = true);
                  AppToast.show(
                    context,
                    message: ref.read(localeProvider) == AppLanguage.fr
                        ? 'Ordonnance téléversée avec succès'
                        : 'Prescription uploaded successfully',
                    type: ToastType.success,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('order.tapToUpload', ref: ref),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('prescription.jpg', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('(0.8 MB)', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                      onPressed: () => setState(() => _hasUploadedRx = false),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── 4. Delivery Option ──
            Text(
              context.tr('order.deliveryOption', ref: ref),
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),

            // Option 1: Pickup at Pharmacy (Free)
            _DeliveryOptionTile(
              title: context.tr('order.pickup', ref: ref),
              priceText: context.tr('order.pickupFree', ref: ref),
              isSelected: _deliveryOption == 'pickup',
              onTap: () => setState(() => _deliveryOption = 'pickup'),
            ),
            const SizedBox(height: 10),

            // Option 2: Home Delivery (1,000 FCFA)
            _DeliveryOptionTile(
              title: context.tr('order.homeDelivery', ref: ref),
              priceText: context.tr('order.homeDeliveryFee', ref: ref),
              isSelected: _deliveryOption == 'home',
              onTap: () => setState(() => _deliveryOption = 'home'),
            ),

            const SizedBox(height: 28),

            // ── 5. Total Price Row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('order.total', ref: ref),
                  style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                Text(
                  '${_formatPrice(_totalPrice)} FCFA',
                  style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── Bottom Fixed Button: Continue ──
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/order-pending-confirmation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: Text(
              context.tr('order.continue', ref: ref),
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryOptionTile extends StatelessWidget {
  final String title;
  final String priceText;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryOptionTile({
    required this.title,
    required this.priceText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
            ),
            Text(
              priceText,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
