import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class AppConfig {
  static const String _configFileName = 'flutter_strings_config.json';
  String? _dartSdkPath;

  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  String? get dartSdkPath => _dartSdkPath;

  Future<void> loadConfig() async {
    try {
      final configFile = await _getConfigFile();
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final config = json.decode(content) as Map<String, dynamic>;
        _dartSdkPath = config['dartSdkPath'] as String?;
      }
    } catch (e) {
      print('Error loading config: $e');
    }
  }

  Future<void> saveConfig(String dartSdkPath) async {
    try {
      final configFile = await _getConfigFile();
      final config = {
        'dartSdkPath': dartSdkPath,
      };
      await configFile.writeAsString(json.encode(config));
      _dartSdkPath = dartSdkPath;
    } catch (e) {
      print('Error saving config: $e');
    }
  }

  Future<File> _getConfigFile() async {
    final appDir = await getApplicationSupportDirectory();
    return File(path.join(appDir.path, _configFileName));
  }
} 