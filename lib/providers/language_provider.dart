import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  final _config = AppConfig();

  LanguageNotifier() : super(const Locale('zh')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    await _config.loadConfig();
    state = Locale(_config.languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    await _config.saveConfig(languageCode: languageCode);
    state = Locale(languageCode);
  }
} 