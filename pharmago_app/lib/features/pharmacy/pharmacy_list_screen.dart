import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/providers/api_providers.dart';

class PharmacyListScreen extends ConsumerStatefulWidget {
  const PharmacyListScreen({super.key});

  @override
  ConsumerState<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends ConsumerState<PharmacyListScreen> {
  String _selectedCity = 'All';
  String _searchQuery = '';
  List<PharmacyModel> _pharmacies = mockPharmacies;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLivePharmacies();
  }

  Future<void> _fetchLivePharmacies() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getPharmacies(
        city: _selectedCity == 'All' ? null : _selectedCity,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['pharmacies'] as List;
        if (list.isNotEmpty) {
          setState(() {
            _pharmacies = list.map((item) {
              return PharmacyModel(
                id: item['id'] ?? 'ph-0',
                name: item['name'] ?? 'Pharmacie',
                address: item['address'] ?? 'Adresse',
                city: item['city'] ?? 'Douala',
                phone: item['phone'] ?? '+237',
                rating: (item['rating'] as num?)?.toDouble() ?? 4.5,
                distanceKm: (item['distanceKm'] as num?)?.toDouble() ?? 0.5,
                isOnDuty: item['isGuard247'] == true,
                isOpen: true,
                openingHours: item['openingHours'] ?? '24h/24',
              );
            }).toList();
          });
        }
      }
    } catch (_) {
      // Offline fallback to mockPharmacies
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    final filtered = _pharmacies.where((p) {
      final matchCity = _selectedCity == 'All' || p.city.toLowerCase() == _selectedCity.toLowerCase();
      final matchSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.address.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCity && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr('pharma.title', ref: ref),
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: context.tr('pharma.searchPlaceholder', ref: ref),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // City Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Douala', 'Yaoundé'].map((city) {
                      final isSelected = _selectedCity == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(city == 'All' ? (isFr ? 'Toutes' : 'All') : city),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCity = city);
                              _fetchLivePharmacies();
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

          // Pharmacy Cards List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pharma = filtered[index];
                      return _PharmacyCardDetailed(pharma: pharma, isFr: isFr);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyCardDetailed extends StatelessWidget {
  final PharmacyModel pharma;
  final bool isFr;

  const _PharmacyCardDetailed({required this.pharma, required this.isFr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pharma.name,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (pharma.isOnDuty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'GARDE 24/7',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${pharma.address} • ${pharma.city}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textBody),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                pharma.openingHours,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 2),
                  Text(
                    '${pharma.rating}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: Text(isFr ? 'Appeler' : 'Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions_outlined, size: 16),
                  label: Text(isFr ? 'Itinéraire' : 'Directions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
