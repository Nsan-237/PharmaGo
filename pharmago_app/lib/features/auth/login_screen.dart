import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/app_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isFr = ref.read(localeProvider) == AppLanguage.fr;

    if (email.isEmpty || password.isEmpty) {
      AppToast.show(context,
          message: isFr
              ? 'Veuillez remplir tous les champs'
              : 'Please fill in all fields',
          type: ToastType.error);
      return;
    }

    final success = await ref.read(authProvider.notifier).login(email, password);

    if (!mounted) return;

    if (success) {
      AppToast.show(context,
          message: isFr ? 'Connexion réussie !' : 'Login successful!',
          type: ToastType.success);
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      AppToast.show(context,
          message: error ?? (isFr ? 'Erreur de connexion' : 'Login failed'),
          type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              avatar: Text(isFr ? '🇫🇷' : '🇬🇧',
                  style: const TextStyle(fontSize: 14)),
              label: Text(
                isFr ? 'FR' : 'EN',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              onPressed: () =>
                  ref.read(localeProvider.notifier).toggleLanguage(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Brand Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.local_pharmacy_rounded,
                      color: AppColors.primary, size: 32),
                ),
              ),
              const SizedBox(height: 24),

              // Heading
              Text(
                context.tr('auth.welcome', ref: ref),
                style: GoogleFonts.sora(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFr
                    ? 'Connectez-vous avec votre email et mot de passe'
                    : 'Sign in with your email and password',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textBody,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Login Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email Field
                    Text(
                      isFr ? 'Email ou téléphone' : 'Email or phone',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText:
                            isFr ? 'votre@email.com' : 'your@email.com',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: AppColors.textMuted, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    Text(
                      isFr ? 'Mot de passe' : 'Password',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: isFr ? 'Votre mot de passe' : 'Your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.textMuted, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isFr ? 'Se connecter' : 'Sign In',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Register link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isFr ? 'Pas encore de compte ? ' : "Don't have an account? ",
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textBody),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        isFr ? "S'inscrire" : 'Register',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Payment Badges
              Center(
                child: Column(
                  children: [
                    Text(
                      isFr
                          ? 'Paiements supportés au Cameroun'
                          : 'Supported payments in Cameroon',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PaymentBadge(
                            name: 'MTN MoMo',
                            color: Color(0xFFFFCC00),
                            textColor: Colors.black),
                        SizedBox(width: 12),
                        _PaymentBadge(
                            name: 'Orange Money',
                            color: Color(0xFFFF6600),
                            textColor: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String name;
  final Color color;
  final Color textColor;

  const _PaymentBadge(
      {required this.name, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Text(name,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor)),
    );
  }
}
