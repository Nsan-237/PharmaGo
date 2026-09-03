import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/app_toast.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = 'momo'; // 'momo', 'orange', 'cash'
  final TextEditingController _phoneController = TextEditingController(text: '677 34 21 09');
  final bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePay() {
    final lang = ref.read(localeProvider);
    final isFr = lang == AppLanguage.fr;

    if (_selectedMethod == 'cash') {
      AppToast.show(
        context,
        message: isFr
            ? 'Commande confirmée ! Paiement en espèces à la livraison.'
            : 'Order confirmed! Cash payment on delivery.',
        type: ToastType.info,
      );
      context.go('/order-confirmed');
      return;
    }

    // For MTN MoMo or Orange Money: open Campay Mobile Money prompt modal
    _showCampayUssdDialog(isFr);
  }

  void _showCampayUssdDialog(bool isFr) {
    final isMtn = _selectedMethod == 'momo';
    final operatorName = isMtn ? 'MTN Mobile Money' : 'Orange Money';
    final ussdCode = isMtn ? '*126#' : '#150#';
    final operatorColor = isMtn ? const Color(0xFFEAB308) : const Color(0xFFF97316);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CampayUssdSheet(
        operatorName: operatorName,
        operatorColor: operatorColor,
        ussdCode: ussdCode,
        phone: _phoneController.text,
        amount: '2 200 FCFA',
        isFr: isFr,
        onSuccess: () {
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: isFr
                ? 'Paiement Campay confirmé avec succès !'
                : 'Campay mobile payment approved successfully!',
            type: ToastType.success,
          );
          context.go('/order-confirmed');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

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
          context.tr('payment.title', ref: ref),
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Total Amount Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('payment.totalAmount', ref: ref),
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '2 200 FCFA',
                      style: GoogleFonts.sora(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        'Passerelle sécurisée Campay Cameroun (MTN / Orange)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 2. Payment Method Section ──
              Text(
                context.tr('payment.paymentMethod', ref: ref),
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // MTN Mobile Money
              _PaymentMethodTile(
                title: context.tr('payment.momo', ref: ref),
                iconColor: const Color(0xFFEAB308),
                badgeText: 'MoMo',
                badgeBg: const Color(0xFFFEF08A),
                subtitle: 'Campay Push USSD (*126#)',
                isSelected: _selectedMethod == 'momo',
                onTap: () => setState(() => _selectedMethod = 'momo'),
              ),
              const SizedBox(height: 10),

              // Orange Money
              _PaymentMethodTile(
                title: context.tr('payment.orange', ref: ref),
                iconColor: const Color(0xFFF97316),
                badgeText: 'OM',
                badgeBg: const Color(0xFFFFEDD5),
                subtitle: 'Campay Push USSD (#150#)',
                isSelected: _selectedMethod == 'orange',
                onTap: () => setState(() => _selectedMethod = 'orange'),
              ),
              const SizedBox(height: 10),

              // Cash on Delivery
              _PaymentMethodTile(
                title: context.tr('payment.cashOnDelivery', ref: ref),
                iconColor: AppColors.success,
                badgeText: 'CASH',
                badgeBg: AppColors.successLight,
                subtitle: isFr ? 'Paiement à la réception' : 'Pay upon delivery',
                isSelected: _selectedMethod == 'cash',
                onTap: () => setState(() => _selectedMethod = 'cash'),
              ),

              if (_selectedMethod != 'cash') ...[
                const SizedBox(height: 20),
                Text(
                  isFr ? 'Numéro de compte Mobile Money (+237)' : 'Mobile Money Account Number (+237)',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Text('🇨🇲 +237', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    hintText: '6XX XX XX XX',
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── 3. Pay Now Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _selectedMethod == 'cash'
                              ? (isFr ? 'Confirmer la commande' : 'Confirm Order')
                              : (isFr ? 'Payer avec Campay' : 'Pay via Campay'),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => context.go('/orders'),
                  child: Text(
                    context.tr('payment.cancel', ref: ref),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Security Footnote
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Paiement certifié Campay • Chiffrement SSL 256-bit',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final Color iconColor;
  final String badgeText;
  final Color badgeBg;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.title,
    required this.iconColor,
    required this.badgeText,
    required this.badgeBg,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Campay USSD Push Prompt Modal Sheet
class _CampayUssdSheet extends StatefulWidget {
  final String operatorName;
  final Color operatorColor;
  final String ussdCode;
  final String phone;
  final String amount;
  final bool isFr;
  final VoidCallback onSuccess;

  const _CampayUssdSheet({
    required this.operatorName,
    required this.operatorColor,
    required this.ussdCode,
    required this.phone,
    required this.amount,
    required this.isFr,
    required this.onSuccess,
  });

  @override
  State<_CampayUssdSheet> createState() => _CampayUssdSheetState();
}

class _CampayUssdSheetState extends State<_CampayUssdSheet> {
  int _secondsLeft = 30;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
        _startCountdown();
      }
    });
  }

  void _simulateValidation() {
    setState(() => _isVerifying = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      widget.onSuccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),

          // Operator Logo & Gateway Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.operatorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.operatorName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: widget.operatorColor),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                child: Text('Campay Gateway', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey.shade700)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            widget.isFr ? 'Demande de paiement envoyée' : 'Payment Request Dispatched',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isFr
                ? 'Un message USSD a été envoyé au +237 ${widget.phone}. Veuillez entrer votre code secret pour valider le montant de ${widget.amount}.'
                : 'A USSD prompt has been sent to +237 ${widget.phone}. Please enter your PIN to authorize ${widget.amount}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody, height: 1.4),
          ),

          const SizedBox(height: 20),

          // USSD Code Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.dialpad_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Code de secours : composer ${widget.ussdCode}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Timer & Verify Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'En attente du PIN (${_secondsLeft}s)...',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action: Simulate validation (ideal for presentation demo)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _simulateValidation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isVerifying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      widget.isFr ? 'Simuler validation USSD (PIN validé)' : 'Simulate USSD Approval (PIN entered)',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
