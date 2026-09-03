import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/mock_data/mock_data.dart';

class HealthTipsScreen extends ConsumerStatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  ConsumerState<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends ConsumerState<HealthTipsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    final categories = ['All', 'Nutrition', 'Wellness', 'Prevention'];

    final filteredTips = _selectedCategory == 'All'
        ? mockHealthTips
        : mockHealthTips.where((t) => t.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          context.tr('tips.title', ref: ref),
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Chips Bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  String label = cat;
                  if (isFr) {
                    if (cat == 'All') label = 'Tous';
                    if (cat == 'Wellness') label = 'Bien-être';
                    if (cat == 'Prevention') label = 'Prévention';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Articles List ──
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final tip = filteredTips[index];
                return _HealthTipCard(tip: tip);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health Tip Card with Real Photo via Unsplash + Graceful Gradient Fallback
// ─────────────────────────────────────────────────────────────────────────────
class _HealthTipCard extends StatelessWidget {
  final HealthTipModel tip;

  const _HealthTipCard({required this.tip});

  List<Color> get _fallbackGradient {
    switch (tip.category) {
      case 'Nutrition':
        return [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)];
      case 'Wellness':
        return [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)];
      case 'Prevention':
        return [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)];
      default:
        return [const Color(0xFFE2F0EC), const Color(0xFFC7E5DC)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Real Photo Banner (140px tall) ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: tip.imageUrl,
                fit: BoxFit.cover,
                // Loading state: gradient shimmer placeholder
                placeholder: (context, url) => _GradientFallback(
                  gradient: _fallbackGradient,
                  iconCode: tip.iconCode,
                ),
                // Network error: same gradient fallback
                errorWidget: (context, url, error) => _GradientFallback(
                  gradient: _fallbackGradient,
                  iconCode: tip.iconCode,
                ),
              ),
            ),
          ),

          // ── Card Content ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tip.category,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  tip.title,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),

                // Summary
                Text(
                  tip.summary,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textBody,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Footer: author + read time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tip.author,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      tip.readTime,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient placeholder shown while the Unsplash image loads or on network error
class _GradientFallback extends StatelessWidget {
  final List<Color> gradient;
  final int iconCode;

  const _GradientFallback({
    required this.gradient,
    required this.iconCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          IconData(iconCode, fontFamily: 'MaterialIcons'),
          color: AppColors.primaryDark.withValues(alpha: 0.35),
          size: 54,
        ),
      ),
    );
  }
}
