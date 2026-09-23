import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/app_toast.dart';

class OtpScreen extends ConsumerStatefulWidget {
  /// Either an email (registration flow) or a phone number (login flow)
  final String contact;
  final bool isEmail;

  const OtpScreen({
    super.key,
    required this.contact,
    this.isEmail = true,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 45;
  Timer? _timer;
  bool _isVerifying = false;

  // Animation for the icon
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );
    _bounceController.forward();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounceController.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _fillDemoOtp() {
    const demoCode = '123456';
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = demoCode[i];
    }
    setState(() {});
    _verifyOtp();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  /// Masks the contact for display: nsan***@gmail.com or +237 6**
  String get _maskedContact {
    if (widget.isEmail) {
      final parts = widget.contact.split('@');
      if (parts.length == 2) {
        final name = parts[0];
        final masked = name.length > 3
            ? '${name.substring(0, 3)}***'
            : '${name[0]}***';
        return '$masked@${parts[1]}';
      }
    }
    // Phone
    if (widget.contact.length > 6) {
      return '${widget.contact.substring(0, 6)}****';
    }
    return widget.contact;
  }

  void _verifyOtp() {
    if (_enteredOtp.length < 6) {
      AppToast.show(
        context,
        message: ref.read(localeProvider) == AppLanguage.fr
            ? 'Veuillez saisir les 6 chiffres du code'
            : 'Please enter all 6 digits',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isVerifying = true);

    // Demo: any 6 digits → go to home (in production: validate against backend)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      AppToast.show(
        context,
        message: ref.read(localeProvider) == AppLanguage.fr
            ? 'Email vérifié avec succès ! Bienvenue 🎉'
            : 'Email verified! Welcome to PharmaGo 🎉',
        type: ToastType.success,
      );
      context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFr = ref.watch(localeProvider) == AppLanguage.fr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark),
          onPressed: () => context.canPop() ? context.pop() : context.go('/register'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Animated Icon ──
              ScaleTransition(
                scale: _bounceAnimation,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Title ──
              Text(
                context.tr('auth.otpTitle', ref: ref),
                style: GoogleFonts.sora(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              // ── Subtitle ──
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textBody, height: 1.4),
                  children: [
                    TextSpan(text: '${context.tr('auth.otpSubtitle', ref: ref)} '),
                    TextSpan(
                      text: _maskedContact,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    TextSpan(
                      text: isFr
                          ? '. Saisissez-le ci-dessous.'
                          : '. Enter it below.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Demo Hint Chip (Interactive for fast testing) ──
              GestureDetector(
                onTap: _isVerifying ? null : _fillDemoOtp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFBD38D)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Text(
                        '${context.tr('auth.otpDemo', ref: ref)} • ${isFr ? 'Appuyez pour tester' : 'Tap to test'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── 6-box OTP Input ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.sora(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _controllers[index].text.isNotEmpty
                                ? AppColors.primary
                                : AppColors.border,
                            width: _controllers[index].text.isNotEmpty ? 2 : 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {}); // rebuild for border color
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_enteredOtp.length == 6) {
                          _verifyOtp();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // ── Verify Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  icon: _isVerifying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                  label: Text(
                    context.tr('auth.verify', ref: ref),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Resend Countdown ──
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        '${context.tr('auth.resendIn', ref: ref)} ${_resendCountdown}s',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                      )
                    : TextButton.icon(
                        onPressed: _startTimer,
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                        label: Text(
                          context.tr('auth.resend', ref: ref),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
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
