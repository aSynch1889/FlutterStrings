import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<bool> {
  final _config = AppConfig();

  ThemeNotifier() : super(false) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    await _config.loadConfig();
    state = _config.isDarkMode;
  }

  Future<void> toggleTheme(bool value) async {
    await _config.saveConfig(isDarkMode: value);
    state = value;
  }
} 