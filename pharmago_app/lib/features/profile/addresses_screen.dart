// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Addresses Screen
// Allows managing delivery addresses with add, select default, and delete.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/app_toast.dart';

class AddressItem {
  final String id;
  final String label;
  final String detail;
  final String city;
  final bool isDefault;

  const AddressItem({
    required this.id,
    required this.label,
    required this.detail,
    required this.city,
    this.isDefault = false,
  });

  AddressItem copyWith({bool? isDefault}) {
    return AddressItem(
      id: id,
      label: label,
      detail: detail,
      city: city,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  final List<AddressItem> _addresses = [
    const AddressItem(
      id: 'addr-1',
      label: 'Domicile / Maison',
      detail: 'Bastos, face Ambassade de Belgique',
      city: 'Yaoundé',
      isDefault: true,
    ),
    const AddressItem(
      id: 'addr-2',
      label: 'Bureau / Lieu de travail',
      detail: 'Akwa, Boulevard de la Liberté',
      city: 'Douala',
      isDefault: false,
    ),
  ];

  void _safePop() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  void _setDefault(String id) {
    setState(() {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == id);
      }
    });
    AppToast.show(context, message: 'Adresse par défaut mise à jour', type: ToastType.info);
  }

  void _deleteAddress(String id) {
    setState(() {
      _addresses.removeWhere((a) => a.id == id);
    });
    AppToast.show(context, message: 'Adresse supprimée', type: ToastType.info);
  }

  void _showAddAddressDialog(bool isFr) {
    _showAddressDialog(isFr, null);
  }

  void _showEditAddressDialog(bool isFr, AddressItem existing) {
    _showAddressDialog(isFr, existing);
  }

  void _showAddressDialog(bool isFr, AddressItem? existing) {
    final isEdit = existing != null;
    final labelCtrl  = TextEditingController(text: existing?.label ?? '');
    final detailCtrl = TextEditingController(text: existing?.detail ?? '');
    String selectedCity = existing?.city ?? 'Yaoundé';

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                isEdit
                    ? (isFr ? 'Modifier l\'adresse' : 'Edit Address')
                    : (isFr ? 'Nouvelle adresse' : 'New Address'),
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: isFr ? 'Nom de l\'adresse (ex: Maison)' : 'Label (e.g. Home)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailCtrl,
                decoration: InputDecoration(
                  labelText: isFr ? 'Quartier / Repère précis' : 'Neighborhood / Landmark',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCity,
                decoration: InputDecoration(
                  labelText: isFr ? 'Ville' : 'City',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Yaoundé',    child: Text('Yaoundé')),
                  DropdownMenuItem(value: 'Douala',     child: Text('Douala')),
                  DropdownMenuItem(value: 'Bafoussam',  child: Text('Bafoussam')),
                  DropdownMenuItem(value: 'Garoua',     child: Text('Garoua')),
                  DropdownMenuItem(value: 'Bertoua',    child: Text('Bertoua')),
                  DropdownMenuItem(value: 'Maroua',     child: Text('Maroua')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedCity = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(isFr ? 'Annuler' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (labelCtrl.text.trim().isEmpty || detailCtrl.text.trim().isEmpty) return;
                setState(() {
                  if (isEdit) {
                    // UPDATE existing
                    final idx = _addresses.indexWhere((a) => a.id == existing.id);
                    if (idx != -1) {
                      _addresses[idx] = AddressItem(
                        id: existing.id,
                        label: labelCtrl.text.trim(),
                        detail: detailCtrl.text.trim(),
                        city: selectedCity,
                        isDefault: existing.isDefault,
                      );
                    }
                  } else {
                    // CREATE new
                    _addresses.add(AddressItem(
                      id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
                      label: labelCtrl.text.trim(),
                      detail: detailCtrl.text.trim(),
                      city: selectedCity,
                      isDefault: _addresses.isEmpty,
                    ));
                  }
                });
                Navigator.pop(dCtx);
                AppToast.show(
                  context,
                  message: isEdit
                      ? (isFr ? 'Adresse mise à jour ✓' : 'Address updated ✓')
                      : (isFr ? 'Adresse ajoutée ✓' : 'Address added ✓'),
                  type: ToastType.success,
                );
              },
              child: Text(
                isEdit ? (isFr ? 'Mettre à jour' : 'Update') : (isFr ? 'Enregistrer' : 'Save'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

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
          isFr ? 'Mes Adresses de livraison' : 'My Delivery Addresses',
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _addresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final addr = _addresses[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: addr.isDefault ? AppColors.primary : AppColors.border,
                width: addr.isDefault ? 1.5 : 1,
              ),
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
                    color: addr.isDefault ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: addr.isDefault ? AppColors.primary : AppColors.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            addr.label,
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (addr.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isFr ? 'Par défaut' : 'Default',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${addr.detail} • ${addr.city}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                  onSelected: (val) {
                    if (val == 'default') _setDefault(addr.id);
                    if (val == 'edit')    _showEditAddressDialog(isFr, addr);
                    if (val == 'delete')  _deleteAddress(addr.id);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(isFr ? 'Modifier' : 'Edit'),
                        ],
                      ),
                    ),
                    if (!addr.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(isFr ? 'Définir par défaut' : 'Set as default'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(isFr ? 'Supprimer' : 'Delete', style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => _showAddAddressDialog(isFr),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            label: Text(
              isFr ? 'Ajouter une adresse' : 'Add an Address',
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
