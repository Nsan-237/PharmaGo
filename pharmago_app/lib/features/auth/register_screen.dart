import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/app_toast.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedCity = 'Yaoundé';
  bool _termsAccepted = false;
  bool _obscurePassword = true;

  final List<String> _cities = [
    'Yaoundé',
    'Douala',
    'Bafoussam',
    'Limbe',
    'Bamenda',
    'Garoua',
    'Buea',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteRegistration() async {
    final isFr = ref.read(localeProvider) == AppLanguage.fr;
    if (_nameController.text.trim().isEmpty) {
      AppToast.show(context,
          message: isFr ? 'Veuillez renseigner votre nom complet' : 'Please enter your full name',
          type: ToastType.error);
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      AppToast.show(context,
          message: isFr ? 'Veuillez renseigner votre email' : 'Please enter your email',
          type: ToastType.error);
      return;
    }
    if (_passwordController.text.length < 6) {
      AppToast.show(context,
          message: isFr ? 'Mot de passe trop court (min 6 caractères)' : 'Password too short (min 6 characters)',
          type: ToastType.error);
      return;
    }
    if (!_termsAccepted) {
      AppToast.show(context,
          message: isFr ? 'Veuillez accepter les conditions' : 'Please accept the terms',
          type: ToastType.error);
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? '+237${_phoneController.text.trim()}' : null,
    );

    if (!mounted) return;

    if (success) {
      AppToast.show(context,
          message: isFr
              ? 'Bienvenue sur PharmaGo !'
              : 'Welcome to PharmaGo!',
          type: ToastType.success);
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      AppToast.show(context,
          message: error ?? (isFr ? 'Erreur d\'inscription' : 'Registration failed'),
          type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isFr = ref.watch(localeProvider) == AppLanguage.fr;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('auth.registerTitle', ref: ref),
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Card
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
                    // Full Name
                    Text(
                      context.tr('auth.fullName', ref: ref),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: context.tr('auth.fullNameHint', ref: ref),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Email
                    Text(
                      context.tr('auth.email', ref: ref),
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
                      decoration: InputDecoration(
                        hintText: context.tr('auth.emailHint', ref: ref),
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // City Dropdown
                    Text(
                      context.tr('auth.city', ref: ref),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: _cities.map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(
                                city,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCity = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Phone Number (+237)
                    Text(
                      ref.read(localeProvider) == AppLanguage.fr ? 'Numéro de téléphone (+237)' : 'Phone Number (+237)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '6XX XX XX XX',
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Text('🇨🇲', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password field
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
                      decoration: InputDecoration(
                        hintText: isFr ? 'Min. 6 caractères' : 'Min. 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      ref.read(localeProvider) == AppLanguage.fr ? 'Adresse de livraison (Quartier / Repère)' : 'Delivery Address (Neighborhood)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: ref.read(localeProvider) == AppLanguage.fr ? 'Ex: Mimboman, Carrefour Don Bosco' : 'e.g., Mimboman, Don Bosco Junction',
                        prefixIcon: const Icon(Icons.home_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _termsAccepted,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) =>
                                setState(() => _termsAccepted = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr('auth.terms', ref: ref),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textBody,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Complete Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleCompleteRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.tr('auth.finish', ref: ref),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
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
