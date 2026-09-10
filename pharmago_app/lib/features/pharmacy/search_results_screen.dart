import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/widgets/adaptive_map_view.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'Amoxicillin 500mg');
  String _selectedCity = 'Tous'; // 'Tous', 'Yaoundé', 'Douala'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    final filteredPharmacies = mockPharmacies.where((p) {
      if (_selectedCity == 'Yaoundé') return p.city == 'Yaoundé';
      if (_selectedCity == 'Douala') return p.city == 'Douala';
      return true;
    }).toList();

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
          context.tr('search.resultsTitle', ref: ref),
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Bar with Clear Button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                  onPressed: () => _searchController.clear(),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          // City Filter Chips (Tous / Yaoundé / Douala)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _buildCityChip('Tous', isFr ? 'Toutes les villes' : 'All Cities'),
                const SizedBox(width: 8),
                _buildCityChip('Yaoundé', 'Yaoundé (5)'),
                const SizedBox(width: 8),
                _buildCityChip('Douala', 'Douala (5)'),
              ],
            ),
          ),

          // Pharmacies Found Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Text(
              isFr
                  ? '${filteredPharmacies.length} pharmacies trouvées à ${_selectedCity == "Tous" ? "Cameroun" : _selectedCity}'
                  : '${filteredPharmacies.length} pharmacies found in ${_selectedCity == "Tous" ? "Cameroon" : _selectedCity}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textBody,
              ),
            ),
          ),

          // Live OpenStreetMap with Multiple Pharmacy Markers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdaptiveMapView(
              height: 145,
              showRoute: false,
              title: '${filteredPharmacies.length} Pharmacies • ${_selectedCity == "Tous" ? "Yaoundé & Douala" : _selectedCity}',
            ),
          ),

          const SizedBox(height: 10),

          // Pharmacy Cards List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: filteredPharmacies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pharma = filteredPharmacies[index];
                return _SearchResultCard(pharmacy: pharma, isFr: isFr);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityChip(String cityKey, String label) {
    final isSelected = _selectedCity == cityKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedCity = cityKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final bool isFr;

  const _SearchResultCard({required this.pharmacy, required this.isFr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pharmacy Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pharmacy.name,
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    // City Tag Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: pharmacy.city == 'Yaoundé'
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: pharmacy.city == 'Yaoundé'
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Text(
                        pharmacy.city,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: pharmacy.city == 'Yaoundé'
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  pharmacy.address,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${pharmacy.distanceKm} km • ${pharmacy.isOpen ? (isFr ? "Ouvert" : "Open") : (isFr ? "Fermé" : "Closed")}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textBody, fontWeight: FontWeight.w500),
                    ),
                    if (pharmacy.isOnDuty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isFr ? 'De garde' : 'On duty',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isFr
                            ? 'En Stock - ${pharmacy.inStockUnits} unités'
                            : 'In Stock - ${pharmacy.inStockUnits} units',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pharmacy.deliveryTimeRange,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Request Button
          ElevatedButton(
            onPressed: () => context.go('/pharmacy-details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isFr ? 'Demander' : 'Request',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
