// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Personal Information Screen
// Allows viewing and updating user profile data connected to the real DB.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/app_toast.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nameController = TextEditingController(text: auth.fullName);
    _phoneController = TextEditingController(text: auth.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _safePop() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  Future<void> _saveProfile(bool isFr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final result = await ref.read(authProvider.notifier).updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      AppToast.show(
        context,
        message: isFr ? 'Profil mis à jour avec succès ✓' : 'Profile updated successfully ✓',
        type: ToastType.success,
      );
      _safePop();
    } else {
      AppToast.show(
        context,
        message: result['error'] ?? (isFr ? 'Erreur lors de la mise à jour' : 'Update failed'),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: _safePop,
        ),
        title: Text(
          isFr ? 'Informations personnelles' : 'Personal Information',
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Profile Card ──
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          auth.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.fullName.isNotEmpty ? auth.fullName : 'Client',
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        auth.role == 'DELIVERY_AGENT'
                            ? (isFr ? 'Agent de livraison' : 'Delivery Agent')
                            : (auth.role == 'PHARMACY_ADMIN'
                                ? 'Pharmacien'
                                : (isFr ? 'Client vérifié' : 'Verified Client')),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Form Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
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
                      isFr ? 'Nom complet' : 'Full Name',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return isFr ? 'Veuillez saisir votre nom' : 'Please enter your name';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Phone Number
                    Text(
                      isFr ? 'Numéro de téléphone' : 'Phone Number',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+237 6xx xx xx xx',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Email (Read-only)
                    Text(
                      isFr ? 'Adresse e-mail (liée au compte)' : 'Email address (linked to account)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              auth.email.isNotEmpty ? auth.email : 'N/A',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : () => _saveProfile(isFr),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                  label: Text(
                    _isSaving
                        ? (isFr ? 'Enregistrement...' : 'Saving...')
                        : (isFr ? 'Enregistrer les modifications' : 'Save Changes'),
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
