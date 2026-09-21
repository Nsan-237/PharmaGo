// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Help & Support Screen
// Provides direct support channels (Phone, WhatsApp, Email) and FAQs.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/app_toast.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(" ", "")}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      AppToast.show(context, message: 'Appel vers $phone...', type: ToastType.info);
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent('Bonjour PharmaGo, j\'ai besoin d\'assistance avec ma commande.')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      AppToast.show(context, message: 'Ouverture de WhatsApp...', type: ToastType.info);
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent('Support PharmaGo')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      AppToast.show(context, message: email, type: ToastType.info);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    final faqs = [
      {
        'q': isFr ? 'Comment commander un médicament ?' : 'How do I order medicine?',
        'a': isFr
            ? 'Recherchez le produit ou la pharmacie de votre choix, ajoutez-le au panier ou téléchargez votre ordonnance via "Demande d\'ordonnance". Notre équipe et la pharmacie valideront votre commande.'
            : 'Search for the medicine or pharmacy of your choice, add to cart or upload your prescription via "Request Order". Our team and the pharmacy will validate your request.',
      },
      {
        'q': isFr ? 'Quels sont les délais de livraison ?' : 'What are the delivery times?',
        'a': isFr
            ? 'En zone urbaine (Douala et Yaoundé), le délai moyen est de 25 à 45 minutes selon l\'affluence et la circulation.'
            : 'In urban zones (Douala and Yaounde), average delivery is 25 to 45 minutes depending on traffic and order volume.',
      },
      {
        'q': isFr ? 'Comment payer (MTN MoMo, Orange Money, Cash) ?' : 'How do I pay (MoMo, Orange Money, Cash)?',
        'a': isFr
            ? 'Vous pouvez régler directement en ligne via MTN MoMo ou Orange Money lors du paiement, ou sélectionner le paiement en espèces à la livraison.'
            : 'You can pay online via MTN Mobile Money or Orange Money at checkout, or select Cash on Delivery to pay the courier.',
      },
      {
        'q': isFr ? 'Comment savoir si une pharmacie est de garde ?' : 'How do I check if a pharmacy is on duty?',
        'a': isFr
            ? 'Les pharmacies de garde sont indiquées par un badge vert "De Garde 24h/24" sur la carte et la liste.'
            : 'On-duty pharmacies are highlighted with a green "On Duty 24/7" badge on the interactive map and search list.',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => _safePop(context),
        ),
        title: Text(
          isFr ? 'Aide & Assistance' : 'Help & Support',
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFr ? 'Assistance PharmaGo 24/7' : 'PharmaGo 24/7 Support',
                          style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFr
                              ? 'Une question sur votre commande ou un médicament ? Contactez-nous à tout moment.'
                              : 'Question about your order or a medicine? Contact us anytime.',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Contact Buttons ──
            Text(
              isFr ? 'Nous contacter directement' : 'Contact Us Directly',
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _ContactCard(
                    icon: Icons.phone_in_talk_rounded,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                    title: isFr ? 'Appeler' : 'Call',
                    subtitle: '+237 694 55 67 93',
                    onTap: () => _launchPhone(context, '+237694556793'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                    title: 'WhatsApp',
                    subtitle: isFr ? 'Discussion instantanée' : 'Instant Chat',
                    onTap: () => _launchWhatsApp(context, '+237694556793'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _ContactCard(
              icon: Icons.email_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEF3C7),
              title: isFr ? 'Support par E-mail' : 'Email Support',
              subtitle: 'nsan237cam@gmail.com',
              onTap: () => _launchEmail(context, 'nsan237cam@gmail.com'),
            ),

            const SizedBox(height: 28),

            // ── FAQ Accordion ──
            Text(
              isFr ? 'Foire aux Questions (FAQ)' : 'Frequently Asked Questions',
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),

            ...faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ExpansionTile(
                shape: const Border(),
                leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                title: Text(
                  faq['q']!,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(
                      faq['a']!,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textBody, height: 1.5),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
