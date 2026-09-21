// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Medicines Catalog Screen
// Displays all medicines with search, category filtering, Rx badges,
// and direct ordering integration.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/mock_data/mock_data.dart';

class MedicinesCatalogScreen extends ConsumerStatefulWidget {
  const MedicinesCatalogScreen({super.key});

  @override
  ConsumerState<MedicinesCatalogScreen> createState() => _MedicinesCatalogScreenState();
}

class _MedicinesCatalogScreenState extends ConsumerState<MedicinesCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tous';
  bool _onlyWithoutRx = false;

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

  void _showDrugDetail(DrugModel drug, bool isFr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Drug Image & Header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    drug.imageUrl,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 76,
                      height: 76,
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.medication_rounded,
                          color: AppColors.primary, size: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          drug.category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        drug.name,
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drug.dosage,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Price & Status row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFr ? 'Prix unitaire' : 'Unit Price',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${drug.price} FCFA',
                        style: GoogleFonts.sora(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: drug.requiresRx
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          drug.requiresRx ? Icons.receipt_long_rounded : Icons.check_circle_rounded,
                          size: 14,
                          color: drug.requiresRx ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          drug.requiresRx
                              ? (isFr ? 'Ordonnance requise' : 'Rx Required')
                              : (isFr ? 'Vente libre' : 'Over the counter'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: drug.requiresRx ? const Color(0xFFB45309) : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/request-order', extra: {
                    'name': drug.name,
                    'price': drug.price,
                    'dosage': drug.dosage,
                    'imageUrl': drug.imageUrl,
                    'requiresPrescription': drug.requiresRx,
                  });
                },
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                label: Text(
                  isFr ? 'Commander ce médicament' : 'Order this medication',
                  style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    // Categories list
    final categories = [
      'Tous',
      'Antibiotique',
      'Analgésique',
      'Antipaludéen',
      'Vitamines',
      'Sirop Toux',
      'Anti-inflammatoire',
    ];

    // Filter drugs
    final query = _searchController.text.trim();
    final filteredDrugs = mockPopularDrugs.where((drug) {
      if (_selectedCategory != 'Tous' && drug.category != _selectedCategory) {
        return false;
      }
      if (_onlyWithoutRx && drug.requiresRx) {
        return false;
      }
      if (query.isNotEmpty) {
        return drugMatchesQuery(drug, query);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: _safePop,
        ),
        title: Text(
          isFr ? 'Catalogue des Médicaments' : 'Medicines Catalog',
          style: GoogleFonts.sora(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter header container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: isFr
                        ? 'Rechercher un médicament, sirop, vitamine...'
                        : 'Search medicine, syrup, vitamin...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                const SizedBox(height: 10),

                // Category Chips horizontal scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            cat == 'Tous' ? (isFr ? 'Tous les produits' : 'All Products') : cat,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Count & Filter Toggle Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFr
                      ? '${filteredDrugs.length} médicament(s) trouvé(s)'
                      : '${filteredDrugs.length} medication(s) found',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _onlyWithoutRx = !_onlyWithoutRx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _onlyWithoutRx ? AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _onlyWithoutRx ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _onlyWithoutRx ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 15,
                          color: _onlyWithoutRx ? AppColors.primary : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFr ? 'Sans ordonnance' : 'No prescription',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _onlyWithoutRx ? AppColors.primary : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Medicines List
          Expanded(
            child: filteredDrugs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.medication_outlined,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          isFr
                              ? 'Aucun médicament ne correspond à votre recherche'
                              : 'No medications match your search',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: filteredDrugs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final drug = filteredDrugs[index];
                      return _MedicinesCatalogCard(
                        drug: drug,
                        isFr: isFr,
                        onTap: () => _showDrugDetail(drug, isFr),
                        onOrder: () => context.push('/request-order', extra: {
                          'name': drug.name,
                          'price': drug.price,
                          'dosage': drug.dosage,
                          'imageUrl': drug.imageUrl,
                          'requiresPrescription': drug.requiresRx,
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MedicinesCatalogCard extends StatelessWidget {
  final DrugModel drug;
  final bool isFr;
  final VoidCallback onTap;
  final VoidCallback onOrder;

  const _MedicinesCatalogCard({
    required this.drug,
    required this.isFr,
    required this.onTap,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Drug Image with Rx Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    drug.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.medication_rounded,
                          color: AppColors.primary, size: 30),
                    ),
                  ),
                ),
                if (drug.requiresRx)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Rx',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          drug.category,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isFr ? 'En stock (${drug.stockCount})' : 'In stock (${drug.stockCount})',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    drug.name,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    drug.dosage,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${drug.price} FCFA',
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      InkWell(
                        onTap: onOrder,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_shopping_cart_rounded,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                isFr ? 'Commander' : 'Order',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
