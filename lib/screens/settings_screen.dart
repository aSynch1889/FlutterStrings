import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import '../core/config.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _config = AppConfig();
  String? _sdkPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    await _config.loadConfig();
    setState(() {
      _sdkPath = _config.dartSdkPath;
      _isLoading = false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    await ref.read(themeProvider.notifier).toggleTheme(value);
  }

  Future<void> _selectDartExecutable() async {
    final String? directoryPath = await file_selector.getDirectoryPath();
    
    if (directoryPath != null) {
      // 从目录路径推导出 SDK 路径
      final sdkPath = path.join(directoryPath, 'cache', 'dart-sdk');
      
      // 验证路径是否有效
      final libPath = '$sdkPath/lib';
      final metadataPath = '$libPath/_internal/sdk_library_metadata/lib/libraries.dart';
      final isValid = await Directory(libPath).exists() && await File(metadataPath).exists();
      
      if (isValid) {
        await _config.saveConfig(dartSdkPath: sdkPath);
        setState(() => _sdkPath = sdkPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.sdkPathUpdated)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.invalidSdkPath)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dartSdkSettings,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dartSdkPath,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _sdkPath ?? l10n.notSet,
                            style: TextStyle(
                              color: _sdkPath == null ? Colors.grey : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _selectDartExecutable,
                            icon: const Icon(Icons.folder_open),
                            label: Text(l10n.selectFlutterSdk),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appearanceSettings,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.darkMode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: isDarkMode,
                            onChanged: _toggleDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.languageSettings,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.language,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                value: 'zh',
                                label: Text('简体中文'),
                                icon: Text('🇨🇳'),
                              ),
                              ButtonSegment<String>(
                                value: 'en',
                                label: Text('English'),
                                icon: Text('🇺🇸'),
                              ),
                            ],
                            selected: {locale.languageCode},
                            onSelectionChanged: (Set<String> newSelection) {
                              ref.read(languageProvider.notifier).setLanguage(newSelection.first);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tips,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.sdkPathTip1}\n'
                    '${l10n.sdkPathTip2}\n'
                    '${l10n.sdkPathTip3}\n'
                    '${l10n.sdkPathTip4}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
} 