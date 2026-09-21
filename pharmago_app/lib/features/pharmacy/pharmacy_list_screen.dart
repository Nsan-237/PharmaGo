import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/providers/api_providers.dart';
import '../../core/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              isFr ? 'Appeler la pharmacie' : 'Call Pharmacy',
                              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        content: Text(
                          '${pharma.name}\n${pharma.phone}',
                          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(isFr ? 'Fermer' : 'Close'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              AppToast.show(
                                context,
                                message: isFr
                                    ? 'Numérotation de ${pharma.phone}...'
                                    : 'Dialing ${pharma.phone}...',
                                type: ToastType.info,
                              );
                            },
                            icon: const Icon(Icons.call, color: Colors.white, size: 16),
                            label: Text(
                              isFr ? 'Composer' : 'Dial',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: Text(isFr ? 'Appeler' : 'Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (bCtx) => Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pharma.name,
                                        style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      ),
                                      Text(
                                        '${pharma.address} • ${pharma.city}',
                                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            // Time and distance estimation pill row
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFBBF7D0)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 20),
                                        const SizedBox(height: 4),
                                        Text(
                                          '~${(pharma.distanceKm * 3.5).round()} min',
                                          style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                        ),
                                        Text(isFr ? 'En voiture' : 'By car', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.directions_walk_rounded, color: Color(0xFF2563EB), size: 20),
                                        const SizedBox(height: 4),
                                        Text(
                                          '~${(pharma.distanceKm * 12).round()} min',
                                          style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF)),
                                        ),
                                        Text(isFr ? 'À pied' : 'Walking', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.straighten_rounded, color: Color(0xFFD97706), size: 20),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${pharma.distanceKm} km',
                                          style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                                        ),
                                        Text(isFr ? 'Distance' : 'Distance', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(bCtx);
                                  final destination = Uri.encodeComponent('${pharma.name}, ${pharma.address}, ${pharma.city}, Cameroun');
                                  final mapUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination');
                                  if (await canLaunchUrl(mapUri)) {
                                    await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                                  } else if (context.mounted) {
                                    AppToast.show(
                                      context,
                                      message: isFr
                                          ? 'Navigation GPS vers ${pharma.name}'
                                          : 'GPS navigation towards ${pharma.name}',
                                      type: ToastType.info,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
                                label: Text(
                                  isFr ? 'Démarrer la navigation GPS' : 'Start GPS Navigation',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
