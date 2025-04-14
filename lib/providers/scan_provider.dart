import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../desktop/file_selector.dart';
import '../core/string_scanner.dart';

class ScanState {
  final String? projectPath;
  final bool isScanning;
  final String? error;
  final Map<String, List<String>>? results;

  ScanState({
    this.projectPath,
    this.isScanning = false,
    this.error,
    this.results,
  });

  ScanState copyWith({
    String? projectPath,
    bool? isScanning,
    String? error,
    Map<String, List<String>>? results,
  }) {
    return ScanState(
      projectPath: projectPath ?? this.projectPath,
      isScanning: isScanning ?? this.isScanning,
      error: error,
      results: results ?? this.results,
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

    state = state.copyWith(isScanning: true, error: null);
    try {
      final results = await _stringScanner.scanProject(state.projectPath!);
      state = state.copyWith(
        isScanning: false,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: e.toString(),
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