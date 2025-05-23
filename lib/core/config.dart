import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _configFileName = 'flutter_strings_config.json';
  String? _dartSdkPath;
  bool _isDarkMode = false;
  String _languageCode = 'zh';
  static AppConfig? _instance;

  factory AppConfig() {
    _instance ??= AppConfig._internal();
    return _instance!;
  }

  AppConfig._internal();

  String? get dartSdkPath => _dartSdkPath;
  bool get isDarkMode => _isDarkMode;
  String get languageCode => _languageCode;

  Future<void> loadConfig() async {
    try {
      // 确保在主 isolate 中运行
      if (!kIsWeb) {
        final configFile = await _getConfigFile();
        if (await configFile.exists()) {
          final content = await configFile.readAsString();
          final config = json.decode(content) as Map<String, dynamic>;
          _dartSdkPath = config['dartSdkPath'] as String?;
          _isDarkMode = config['isDarkMode'] as bool? ?? false;
          _languageCode = config['languageCode'] as String? ?? 'zh';
        }
      }
    } catch (e) {
      print('Error loading config: $e');
    }
  }

  Future<void> saveConfig({String? dartSdkPath, bool? isDarkMode, String? languageCode}) async {
    try {
      // 确保在主 isolate 中运行
      if (!kIsWeb) {
        final configFile = await _getConfigFile();
        final config = {
          'dartSdkPath': dartSdkPath ?? _dartSdkPath,
          'isDarkMode': isDarkMode ?? _isDarkMode,
          'languageCode': languageCode ?? _languageCode,
        };
        await configFile.writeAsString(json.encode(config));
        if (dartSdkPath != null) _dartSdkPath = dartSdkPath;
        if (isDarkMode != null) _isDarkMode = isDarkMode;
        if (languageCode != null) _languageCode = languageCode;
      }
    } catch (e) {
      print('Error saving config: $e');
    }
  }

  Future<File> _getConfigFile() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      return File(path.join(appDir.path, _configFileName));
    } catch (e) {
      print('Error getting config file: $e');
      // 如果无法获取应用支持目录，使用临时目录
      final tempDir = Directory.systemTemp;
      return File(path.join(tempDir.path, _configFileName));
    }
  }
} 