import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // 导入 compute
import '../desktop/file_selector.dart';
import '../core/string_scanner.dart'; // 确保 StringScanner 和它的方法签名在这里定义

class ScanState {
  final String? projectPath;
  final bool isScanning;
  final String? error;
  final Map<String, List<String>>? results;
  final int totalFiles;
  final int scannedFiles;
  final String? currentFile;

  ScanState({
    this.projectPath,
    this.isScanning = false,
    this.error,
    this.results,
    this.totalFiles = 0,
    this.scannedFiles = 0,
    this.currentFile,
  });

  double get progress => totalFiles == 0 ? 0 : scannedFiles / totalFiles;

  ScanState copyWith({
    String? projectPath,
    bool? isScanning,
    String? error,
    Map<String, List<String>>? results,
    int? totalFiles,
    int? scannedFiles,
    String? currentFile,
  }) {
    return ScanState(
      projectPath: projectPath ?? this.projectPath,
      isScanning: isScanning ?? this.isScanning,
      error: error,
      results: results ?? this.results,
      totalFiles: totalFiles ?? this.totalFiles,
      scannedFiles: scannedFiles ?? this.scannedFiles,
      currentFile: currentFile,
    );
  }
}

// 1. 创建一个顶层函数用于 compute
// 注意：这个函数在独立的 Isolate 中运行，不能直接访问 ScanNotifier 的 state
// 它也不能直接使用 ScanNotifier 里的实例变量
// 它接收项目路径作为参数，并返回扫描结果
Future<Map<String, List<String>>> _scanProjectIsolate(String projectPath) async {
  // 在 Isolate 中创建 StringScanner 实例
  final stringScanner = StringScanner();
  // 调用扫描方法，并提供必需的 onStart 和 onProgress 参数 (即使是空实现)
  // 假设 StringScanner.scanProject 需要 onStart 和 onProgress
  final results = await stringScanner.scanProject(
    projectPath,
    onStart: (total) {
      // 在 isolate 中无法更新主 UI 状态，留空或进行 isolate 内部的日志记录
      debugPrint('[Isolate] Scan started. Total files: $total');
    },
    onProgress: (file, scannedCount) {
      // 在 isolate 中无法更新主 UI 状态，留空或进行 isolate 内部的日志记录
      // 可以考虑使用 SendPort/ReceivePort 传递进度，但这里简化处理
      debugPrint('[Isolate] Scanning: $file ($scannedCount)');
    },
  );
  return results;
}


class ScanNotifier extends StateNotifier<ScanState> {
  final FileSelector _fileSelector;
  // StringScanner 实例不再需要在这里持有

  // 2. 修正构造函数语法
  ScanNotifier({
    FileSelector? fileSelector, // 移除 StringScanner 参数
  }) : _fileSelector = fileSelector ?? FileSelector(), // 修正初始化列表
       super(ScanState()); // super 调用放在初始化列表末尾

  Future<void> selectProject() async {
    final path = await _fileSelector.getDirectoryPath();
    if (path != null) {
      state = state.copyWith(
        projectPath: path,
        results: null,
        error: null,
      );
    }
  }

  void setProjectPath(String path) {
    state = state.copyWith(
      projectPath: path,
      results: null,
      error: null,
    );
  }

  // 3. 修改 scanProject 方法以使用 compute (保持不变)
  Future<void> scanProject() async {
    if (state.projectPath == null || state.isScanning) return;

    state = state.copyWith(
      isScanning: true,
      error: null,
      results: null,
      totalFiles: 0,
      scannedFiles: 0,
      currentFile: null,
      // progress: 0.0, // 移除或保持为0，因为进度条将是不确定的
    );

    try {
      final results = await compute(_scanProjectIsolate, state.projectPath!);

      if (!mounted) return; // 检查 Notifier 是否还存在
      if (!state.isScanning) {
          return; // 如果在 compute 期间调用了 stopScan，则不更新结果
      }

      state = state.copyWith(
        isScanning: false,
        results: results,
        totalFiles: results.keys.length,
        scannedFiles: results.keys.length,
        // progress: 1.0, // 标记为完成
      );
    } catch (e) {
      if (!mounted) return;
      if (!state.isScanning) {
          return; // 如果在 compute 期间调用了 stopScan，则不更新错误
      }
      state = state.copyWith(
        isScanning: false,
        error: '扫描出错: $e',
      );
    }
  }

  // 4. 添加 stopScan 方法 (保持不变)
  void stopScan() {
    if (state.isScanning) {
      state = state.copyWith(isScanning: false);
    }
  }

  Future<void> exportAsJson() async {
    if (state.results == null) return;
    
    try {
      final path = await _fileSelector.exportAsJson(state.results!);
      if (path != null) {
        print('Results exported to: $path');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to export results: $e');
    }
  }

  Future<void> exportAsCsv() async {
    if (state.results == null) return;
    
    try {
      final path = await _fileSelector.exportAsCsv(state.results!);
      if (path != null) {
        print('Results exported to CSV: $path');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to export CSV: $e');
    }
  }

  Future<void> exportAsArb() async {
    if (state.results == null) return;
    
    try {
      final path = await _fileSelector.exportAsArb(state.results!);
      if (path != null) {
        print('Results exported to ARB: $path');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to export ARB: $e');
    }
  }
}

// 确保 scanProvider 定义在所有类和函数之后，并且没有语法错误
final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  // 传递 FileSelector 实例（如果需要 mock 或特定实现）
  // final fileSelector = ref.watch(fileSelectorProvider); // 如果有单独的 provider
  return ScanNotifier(
    // fileSelector: fileSelector, // 如果需要注入
  );
});