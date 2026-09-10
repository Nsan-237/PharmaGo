import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  Uint8List? _rxImageBytes;
  String? _rxImageName;
  String? _rxImageSize;
  final ImagePicker _picker = ImagePicker();
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

  Future<void> _pickPrescription(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (xFile == null) return;

      final bytes = await xFile.readAsBytes();
      final sizeKb = (bytes.lengthInBytes / 1024).round();
      final sizeStr = sizeKb > 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '$sizeKb KB';

      setState(() {
        _rxImageBytes = bytes;
        _rxImageName = xFile.name;
        _rxImageSize = sizeStr;
      });

      if (mounted) {
        final isFr = ref.read(localeProvider) == AppLanguage.fr;
        AppToast.show(
          context,
          message: isFr
              ? 'Ordonnance ajoutée : ${xFile.name}'
              : 'Prescription attached: ${xFile.name}',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Erreur: $e',
          type: ToastType.error,
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
                isFr ? 'Téléverser une ordonnance' : 'Upload Prescription',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                isFr
                    ? 'Prenez une photo claire ou choisissez depuis vos fichiers'
                    : 'Take a clear photo or choose from files',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _pickPrescription(ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                      label: Text(
                        isFr ? 'Appareil photo' : 'Camera',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _pickPrescription(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                      label: Text(
                        isFr ? 'Galerie / Fichiers' : 'Gallery / Files',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
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
            if (_rxImageBytes == null)
              GestureDetector(
                onTap: () => _showImageSourceSheet(ref.read(localeProvider) == AppLanguage.fr),
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
                      const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 34),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('order.tapToUpload', ref: ref),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ref.read(localeProvider) == AppLanguage.fr
                            ? 'Format JPG, PNG, PDF acceptés'
                            : 'JPG, PNG, PDF formats accepted',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Real Thumbnail Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _rxImageBytes!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                ref.read(localeProvider) == AppLanguage.fr ? 'Ordonnance jointe' : 'Prescription attached',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _rxImageName ?? 'prescription.jpg',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_rxImageSize != null)
                            Text(_rxImageSize!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                      tooltip: ref.read(localeProvider) == AppLanguage.fr ? 'Supprimer' : 'Remove',
                      onPressed: () => setState(() {
                        _rxImageBytes = null;
                        _rxImageName = null;
                        _rxImageSize = null;
                      }),
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
