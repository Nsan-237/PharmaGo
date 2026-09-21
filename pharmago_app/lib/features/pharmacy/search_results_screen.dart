import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/widgets/adaptive_map_view.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchResultsScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final TextEditingController _searchController;
  String _selectedCity = 'Tous'; // 'Tous', 'Yaoundé', 'Douala'

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _safePop() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;
    final query = _searchController.text.trim();

    // 1. Find matching drugs using fuzzy/accent/dosage-insensitive matcher
    final matchingDrugs = query.isEmpty
        ? <DrugModel>[]
        : mockPopularDrugs.where((d) => drugMatchesQuery(d, query)).toList();

    // 2. Filter pharmacies by city and search query
    final normQuery = normalizeDrugSearch(query);
    final filteredPharmacies = mockPharmacies.where((p) {
      if (_selectedCity == 'Yaoundé' && p.city != 'Yaoundé') return false;
      if (_selectedCity == 'Douala' && p.city != 'Douala') return false;

      if (normQuery.isEmpty) return true;

      final matchesName = normalizeDrugSearch(p.name).contains(normQuery);
      final matchesAddress = normalizeDrugSearch(p.address).contains(normQuery);
      final matchesCity = normalizeDrugSearch(p.city).contains(normQuery);
      final hasMatchingDrug = matchingDrugs.isNotEmpty;

      return matchesName || matchesAddress || matchesCity || hasMatchingDrug;
    }).toList();

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
          context.tr('search.resultsTitle', ref: ref),
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            tooltip: isFr ? 'Filtres' : 'Filters',
            onPressed: () {
              // Quick clear or filter reset
              setState(() {
                _selectedCity = 'Tous';
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Input Bar with Neutral Placeholder & Clear Button ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isFr
                    ? 'Rechercher un médicament (ex: Paracétamol, Métronidazole...)'
                    : 'Search medication (e.g. Paracetamol, Metronidazole...)',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Quick Suggestion Chips (when query is empty) ──
          if (query.isEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      isFr ? 'Exemples :' : 'Try :',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    ...['Paracétamol', 'Métronidazole', 'Amoxicilline', 'Coartem', 'Vitamine C'].map(
                      (example) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(example),
                          labelStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                          backgroundColor: AppColors.primaryLight,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _searchController.text = example;
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── City Filter Chips (Tous / Yaoundé / Douala) ──
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

          // ── Pharmacies / Results Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFr
                      ? '${filteredPharmacies.length} pharmacies trouvées à ${_selectedCity == "Tous" ? "Cameroun" : _selectedCity}'
                      : '${filteredPharmacies.length} pharmacies found in ${_selectedCity == "Tous" ? "Cameroon" : _selectedCity}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
                if (matchingDrugs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFr
                          ? '${matchingDrugs.length} médicament(s) en stock'
                          : '${matchingDrugs.length} med(s) in stock',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Live OpenStreetMap with Multiple Pharmacy Markers ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdaptiveMapView(
              height: 130,
              showRoute: false,
              title: '${filteredPharmacies.length} Pharmacies • ${_selectedCity == "Tous" ? "Yaoundé & Douala" : _selectedCity}',
            ),
          ),

          const SizedBox(height: 8),

          // ── Content Area: Matching Drugs Section + Pharmacy Cards ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                // 1. If user searched a drug and we have matches, display them clearly at the top
                if (matchingDrugs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.medication_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          isFr ? 'Médicaments trouvés' : 'Medications found',
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                  ...matchingDrugs.map((drug) => _MatchingDrugCard(drug: drug, isFr: isFr)),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          isFr ? 'Pharmacies détentrices' : 'Stocking Pharmacies',
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                ],

                // 2. Pharmacies List
                if (filteredPharmacies.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          isFr
                              ? 'Aucun résultat trouvé pour "$query"'
                              : 'No results found for "$query"',
                          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isFr
                              ? 'Essayez de rechercher le nom générique (ex: Paracétamol, Métronidazole, Coartem).'
                              : 'Try searching the generic molecule name (e.g. Paracetamol, Metronidazole, Coartem).',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/medicines'),
                          icon: const Icon(Icons.menu_book_rounded, size: 16),
                          label: Text(
                            isFr ? 'Voir tout le catalogue' : 'Browse full catalog',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredPharmacies.map((pharma) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SearchResultCard(
                          pharmacy: pharma,
                          isFr: isFr,
                          searchedDrugName: matchingDrugs.isNotEmpty ? matchingDrugs.first.name : null,
                        ),
                      )),
                const SizedBox(height: 16),
              ],
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

class _MatchingDrugCard extends StatelessWidget {
  final DrugModel drug;
  final bool isFr;

  const _MatchingDrugCard({required this.drug, required this.isFr});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              drug.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: AppColors.primaryLight,
                child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 26),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.name,
                  style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  '${drug.dosage} • ${drug.price} FCFA',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  drug.requiresRx
                      ? (isFr ? 'Ordonnance requise' : 'Rx Required')
                      : (isFr ? 'Vente libre' : 'Over the counter'),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: drug.requiresRx ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              context.push('/request-order', extra: {
                'name': drug.name,
                'price': drug.price,
                'dosage': drug.dosage,
                'imageUrl': drug.imageUrl,
                'requiresPrescription': drug.requiresRx,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              isFr ? 'Commander' : 'Order',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final bool isFr;
  final String? searchedDrugName;

  const _SearchResultCard({
    required this.pharmacy,
    required this.isFr,
    this.searchedDrugName,
  });

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
          // Distinctive Pharmacy Storefront Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.network(
                pharmacy.displayImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primaryLight,
                  child: const Center(
                    child: Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 26),
                  ),
                ),
              ),
            ),
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
            onPressed: () {
              if (searchedDrugName != null) {
                context.push('/request-order', extra: {
                  'name': searchedDrugName,
                  'pharmacyName': pharmacy.name,
                });
              } else {
                context.go('/pharmacy-details');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
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
