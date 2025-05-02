import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/scan_provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:io';
import 'screens/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '字符串扫描器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
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
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('字符串扫描器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
      body: Row(
        children: [
          // 左侧面板
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
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
                  const Text(
                    '字符串扫描器',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '扫描项目中的字符串',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 扫描控制区域
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '扫描控制',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
                                color: isDragging ? colorScheme.primary : Colors.grey[400]!,
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
                                        color: isDragging ? colorScheme.primary : colorScheme.primary,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        state.projectPath ?? '点击或将文件夹拖拽到此处',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey[600],
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
                                  // 添加停止逻辑
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
                                  state.isScanning ? '停止扫描' : '开始扫描',
                                ),
                              ),
                              if (state.isScanning) ...[
                                const SizedBox(height: 16),
                                // 使用不确定进度条
                                LinearProgressIndicator(
                                  value: null, // 设置为 null 表示不确定进度
                                  backgroundColor: Colors.grey[200],
                                ),
                                const SizedBox(height: 8),
                                // 可以显示一个通用的扫描中提示
                                Text(
                                  '正在扫描项目...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // 移除显示具体文件和进度的 Text Widgets
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
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '扫描统计',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStatItem(
                          icon: Icons.text_fields,
                          label: '字符串数量',
                          value: state.results?.values
                              .fold(0, (sum, strings) => sum + strings.length)
                              .toString() ?? '0',
                        ),
                        const SizedBox(height: 10),
                        _buildStatItem(
                          icon: Icons.insert_drive_file,
                          label: '文件数量',
                          value: state.results?.length.toString() ?? '0',
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
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '导出选项',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildExportButton(
                            icon: Icons.code,
                            label: '导出为 JSON',
                            onPressed: () => ref.read(scanProvider.notifier).exportAsJson(),
                          ),
                          const SizedBox(height: 10),
                          _buildExportButton(
                            icon: Icons.table_chart,
                            label: '导出为 CSV',
                            onPressed: () => ref.read(scanProvider.notifier).exportAsCsv(),
                          ),
                          const SizedBox(height: 10),
                          _buildExportButton(
                            icon: Icons.language,
                            label: '导出本地化文件',
                            onPressed: () => ref.read(scanProvider.notifier).exportAsArb(),
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
                color: Colors.white,
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
                            style: const TextStyle(color: Colors.red),
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
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '无结果',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '选择要扫描字符串的项目文件夹',
                                    style: TextStyle(
                                      color: Colors.grey[400],
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
                                    leading: const Icon(Icons.description_outlined),
                                    title: Text(
                                      entry.key.split('/').last,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${entry.value.length} 个字符串',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    children: entry.value.map((str) => ListTile(
                                      title: Text(
                                        str,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '长度: ${str.length}${str.contains('\n') ? ' (多行)' : ''}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('字符串详情'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('文件: ${entry.key}'),
                                                  const SizedBox(height: 8),
                                                  const Text('内容:'),
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 8),
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: SelectableText(
                                                      str,
                                                      style: const TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('关闭'),
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
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
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