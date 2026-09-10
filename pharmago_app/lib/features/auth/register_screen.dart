import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Marie Ngono');
  final TextEditingController _emailController =
      TextEditingController(text: 'marie.ngono@gmail.com');
  final TextEditingController _phoneController =
      TextEditingController(text: '677 34 21 09');
  final TextEditingController _addressController =
      TextEditingController(text: 'Mimboman, Carrefour Don Bosco');
  String _selectedCity = 'Yaoundé';
  bool _termsAccepted = true;
  bool _isLoading = false;

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
    super.dispose();
  }

  void _handleCompleteRegistration() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(localeProvider) == AppLanguage.fr
                ? 'Veuillez renseigner votre nom complet'
                : 'Please enter your full name',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(localeProvider) == AppLanguage.fr
                ? 'Veuillez accepter les conditions d\'utilisation'
                : 'Please accept the Terms of Service',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

                    // Delivery Address / Quartier
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
                        onPressed: _isLoading ? null : _handleCompleteRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
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
