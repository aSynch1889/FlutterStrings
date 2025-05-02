import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import '../core/config.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        await _config.saveConfig(sdkPath);
        setState(() => _sdkPath = sdkPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SDK 路径已更新')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法找到有效的 SDK 路径，请确保选择了正确的 Flutter SDK 目录')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dart SDK 设置',
                    style: TextStyle(
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
                          const Text(
                            'Dart SDK 路径',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _sdkPath ?? '未设置',
                            style: TextStyle(
                              color: _sdkPath == null ? Colors.grey : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _selectDartExecutable,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('选择 Flutter SDK 目录'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '提示：',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 请选择 Flutter SDK 的根目录\n'
                    '• 通常位于：flutter/\n'
                    '• 系统会自动推导出正确的 SDK 路径\n'
                    '• 如果找不到 SDK，请确保已正确安装 Flutter',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
} 