import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Reusable toast/snackbar system for PharmaGo.
/// Usage: AppToast.show(context, message: 'Prescription uploaded!', type: ToastType.success)
enum ToastType { success, error, info, warning }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final config = _ToastConfig.forType(type);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: config.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: config.shadowColor.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: config.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: config.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Color iconBg;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  const _ToastConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.iconBg,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });

  static _ToastConfig forType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const _ToastConfig(
          backgroundColor: Color(0xFFF0FDF4),
          borderColor: Color(0xFFBBF7D0),
          shadowColor: Color(0xFF006C59),
          iconBg: Color(0xFFDCFCE7),
          iconColor: AppColors.primary,
          textColor: Color(0xFF14532D),
          icon: Icons.check_circle_rounded,
        );
      case ToastType.error:
        return const _ToastConfig(
          backgroundColor: Color(0xFFFFF1F2),
          borderColor: Color(0xFFFFCDD2),
          shadowColor: Color(0xFFDC2626),
          iconBg: Color(0xFFFFE4E6),
          iconColor: AppColors.error,
          textColor: Color(0xFF991B1B),
          icon: Icons.error_rounded,
        );
      case ToastType.warning:
        return const _ToastConfig(
          backgroundColor: Color(0xFFFFFBEB),
          borderColor: Color(0xFFFDE68A),
          shadowColor: Color(0xFFD97706),
          iconBg: Color(0xFFFEF3C7),
          iconColor: Color(0xFFD97706),
          textColor: Color(0xFF92400E),
          icon: Icons.warning_amber_rounded,
        );
      case ToastType.info:
        return const _ToastConfig(
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
          shadowColor: Color(0xFF3B82F6),
          iconBg: Color(0xFFDBEAFE),
          iconColor: Color(0xFF2563EB),
          textColor: Color(0xFF1E40AF),
          icon: Icons.info_rounded,
        );
    }
  }
}
