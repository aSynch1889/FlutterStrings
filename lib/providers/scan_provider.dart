import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../desktop/file_selector.dart';
import '../core/string_scanner.dart';

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

class ScanNotifier extends StateNotifier<ScanState> {
  final FileSelector _fileSelector;
  final StringScanner _stringScanner;

  ScanNotifier({
    FileSelector? fileSelector,
    StringScanner? stringScanner,
  }) : _fileSelector = fileSelector ?? FileSelector(),
       _stringScanner = stringScanner ?? StringScanner(),
       super(ScanState());

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

  Future<void> scanProject() async {
    if (state.projectPath == null) return;

    state = state.copyWith(
      isScanning: true,
      error: null,
      results: null,
      totalFiles: 0,
      scannedFiles: 0,
      currentFile: null,
    );

    try {
      final results = await _stringScanner.scanProject(
        state.projectPath!,
        onStart: (totalFiles) {
          state = state.copyWith(totalFiles: totalFiles);
        },
        onProgress: (file, scannedFiles) {
          state = state.copyWith(
            currentFile: file,
            scannedFiles: scannedFiles,
          );
        },
      );
      
      state = state.copyWith(
        isScanning: false,
        results: results,
        currentFile: null,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: e.toString(),
        currentFile: null,
      );
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

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier();
});