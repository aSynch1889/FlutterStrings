import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/settings_screen.dart';
import 'core/config.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/scan_provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:io';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);
    
    return MaterialApp(
      title: '字符串扫描器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : Colors.grey[100],
      body: Row(
        children: [
          // 左侧面板
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: colorScheme.onSurface),
                        tooltip: l10n.settings,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    l10n.selectProjectFolder,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 扫描控制区域
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceVariant : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? colorScheme.outline : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.scanControl,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 项目选择区域
                        GestureDetector(
                          onTap: () => ref.read(scanProvider.notifier).selectProject(),
                          child: DragTarget<String>(
                            onAccept: (path) {
                              if (Directory(path).existsSync()) {
                                ref.read(scanProvider.notifier).setProjectPath(path);
                              }
                            },
                            onWillAccept: (data) {
                              return data != null && Directory(data).existsSync();
                            },
                            builder: (context, candidateData, rejectedData) {
                              final isDragging = candidateData.isNotEmpty;
                              return DottedBorder(
                                color: isDragging ? colorScheme.primary : colorScheme.outline,
                                strokeWidth: 1,
                                dashPattern: const [6, 3],
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(8),
                                padding: EdgeInsets.zero,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDragging ? colorScheme.primary.withOpacity(0.05) : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.folder_open_outlined,
                                        size: 40,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        state.projectPath ?? l10n.selectProjectFolder,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 扫描按钮和进度
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.icon(
                                onPressed: () {
                                  if (state.isScanning) {
                                    ref.read(scanProvider.notifier).stopScan();
                                  } else {
                                    if (state.projectPath != null) {
                                      ref.read(scanProvider.notifier).scanProject();
                                    } else {
                                      ref.read(scanProvider.notifier).selectProject();
                                    }
                                  }
                                },
                                icon: Icon(
                                  state.isScanning ? Icons.stop : Icons.play_arrow,
                                ),
                                label: Text(
                                  state.isScanning ? l10n.stopScan : l10n.scanProject,
                                ),
                              ),
                              if (state.isScanning) ...[
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: null,
                                  backgroundColor: colorScheme.surfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.scanning,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 扫描统计
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceVariant : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? colorScheme.outline : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.scanStats,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStatItem(
                          icon: Icons.text_fields,
                          label: l10n.stringCount,
                          value: state.results?.values
                              .fold(0, (sum, strings) => sum + strings.length)
                              .toString() ?? '0',
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 10),
                        _buildStatItem(
                          icon: Icons.insert_drive_file,
                          label: l10n.fileCount,
                          value: state.results?.length.toString() ?? '0',
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 导出选项
                  if (state.results != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceVariant : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? colorScheme.outline : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.exportOptions,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildExportButton(
                            icon: Icons.code,
                            label: l10n.exportAsJson,
                            onPressed: () => ref.read(scanProvider.notifier).exportAsJson(),
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 10),
                          _buildExportButton(
                            icon: Icons.table_chart,
                            label: l10n.exportAsCsv,
                            onPressed: () => ref.read(scanProvider.notifier).exportAsCsv(),
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 10),
                          _buildExportButton(
                            icon: Icons.language,
                            label: l10n.exportAsArb,
                            onPressed: () => ref.read(scanProvider.notifier).exportAsArb(),
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 右侧结果展示区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: state.isScanning
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(
                          child: Text(
                            state.error!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        )
                      : state.results == null || state.results!.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_outlined,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noResults,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.selectProjectFolder,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: state.results!.length,
                              itemBuilder: (context, index) {
                                final entry = state.results!.entries.elementAt(index);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ExpansionTile(
                                    leading: Icon(Icons.description_outlined, color: colorScheme.primary),
                                    title: Text(
                                      entry.key.split('/').last,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${entry.value.length} ${l10n.stringCount}',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    children: entry.value.map((str) => ListTile(
                                      title: Text(
                                        str,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${l10n.length}: ${str.length}${str.contains('\n') ? l10n.multiline : ''}',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              l10n.stringDetails,
                                              style: TextStyle(color: colorScheme.onSurface),
                                            ),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${l10n.file}: ${entry.key}',
                                                    style: TextStyle(color: colorScheme.onSurface),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '${l10n.content}:',
                                                    style: TextStyle(color: colorScheme.onSurface),
                                                  ),
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 8),
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.surfaceVariant,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: SelectableText(
                                                      str,
                                                      style: TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 14,
                                                        color: colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: Text(l10n.close),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )).toList(),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}