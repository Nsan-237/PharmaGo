import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'translations_en.dart';
import 'translations_fr.dart';

/// Supported Locales
enum AppLanguage { fr, en }

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.fr); // Default to French for Cameroon

  void toggleLanguage() {
    state = state == AppLanguage.fr ? AppLanguage.en : AppLanguage.fr;
  }

  void setLanguage(AppLanguage lang) {
    state = lang;
  }
}

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    // Fallback if accessed without provider scope
    return AppLocalizations(AppLanguage.fr);
  }

  String tr(String key) {
    final map = language == AppLanguage.fr ? translationsFr : translationsEn;
    return map[key] ?? key;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key, {WidgetRef? ref}) {
    if (ref != null) {
      final lang = ref.watch(localeProvider);
      final map = lang == AppLanguage.fr ? translationsFr : translationsEn;
      return map[key] ?? key;
    }
    // Default lookup
    return translationsFr[key] ?? key;
  }
}
