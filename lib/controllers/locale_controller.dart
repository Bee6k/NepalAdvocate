import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/storage_service.dart';

class LocaleController extends StateNotifier<Locale> {
  final StorageService _storage = StorageService();

  LocaleController() : super(const Locale('en')) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await _storage.getLanguage();
    if (savedLanguage != null) {
      state = Locale(savedLanguage);
    }
  }

  Future<void> setLanguage(Locale locale) async {
    state = locale;
    await _storage.saveLanguage(locale.languageCode);
  }
}

final localeControllerProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});

