import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart';
import 'dart:io';

class StringScanner {
  final List<String> excludedFolders = [
    'build',
    '.dart_tool',
    'packages',
    'ios',
    'android',
    'lib/generated'
  ];

  Future<Map<String, List<String>>> scanProject(
    String projectPath, {
    required void Function(int totalFiles) onStart,
    required void Function(String file, int scannedFiles) onProgress,
  }) async {
    final results = <String, List<String>>{};
    final excludedPaths = excludedFolders
        .map((folder) => join(projectPath, folder))
        .toList();

    // 获取 Dart SDK 路径
    final sdkPath = await _getDartSdkPath();
    if (sdkPath == null) {
      throw Exception('Cannot find Dart SDK path. Please make sure Flutter is properly installed.');
    }

    print('Using Dart SDK path: $sdkPath');

    final collection = AnalysisContextCollection(
      includedPaths: [projectPath],
      excludedPaths: excludedPaths,
      sdkPath: sdkPath,
    );

    // 获取所有需要分析的文件
    final allFiles = <String>[];
    for (final context in collection.contexts) {
      allFiles.addAll(
        context.contextRoot.analyzedFiles()
            .where((path) => path.endsWith('.dart'))
            .where((path) => !excludedPaths.any((excluded) => path.startsWith(excluded)))
      );
    }

    // 通知总文件数
    onStart(allFiles.length);

    // 分析每个文件
    int scannedCount = 0;
    for (final context in collection.contexts) {
      final analyzedFiles = context.contextRoot.analyzedFiles()
          .where((path) => path.endsWith('.dart'))
          .where((path) => !excludedPaths.any((excluded) => path.startsWith(excluded)));

      for (final filePath in analyzedFiles) {
        // 通知当前进度
        onProgress(filePath, ++scannedCount);

        final result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          final visitor = _StringLiteralVisitor();
          result.unit.accept(visitor);
          if (visitor.strings.isNotEmpty) {
            results[filePath] = visitor.strings;
          }
        }
      }
    }

    return results;
  }

  String? _getDartSdkPath() {
    // 验证 SDK 路径是否有效
    bool isValidSdkPath(String path) {
      try {
        final libPath = join(path, 'lib');
        final metadataPath = join(libPath, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart');
        return Directory(libPath).existsSync() && File(metadataPath).existsSync();
      } catch (e) {
        print('Error validating SDK path: $e');
        return false;
      }
    }

    // 尝试从 Flutter 环境变量获取
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final dartSdkPath = join(flutterRoot, 'bin', 'cache', 'dart-sdk');
      print('Trying Flutter Dart SDK path: $dartSdkPath');
      if (isValidSdkPath(dartSdkPath)) {
        return dartSdkPath;
      }
    }

    // 尝试从系统路径获取
    final systemPaths = [
      '/usr/local/opt/dart/libexec',  // Homebrew 安装路径
      '/usr/lib/dart',                 // 系统安装路径
      Platform.environment['HOME'] != null 
        ? join(Platform.environment['HOME']!, 'development', 'flutter', 'bin', 'cache', 'dart-sdk')
        : null,
    ].whereType<String>();

    for (final path in systemPaths) {
      print('Trying system Dart SDK path: $path');
      if (isValidSdkPath(path)) {
        return path;
      }
    }

    // 尝试直接使用 Flutter 默认路径
    final defaultFlutterPath = '/Users/huazi/development/flutter/bin/cache/dart-sdk';
    print('Trying default Flutter path: $defaultFlutterPath');
    if (isValidSdkPath(defaultFlutterPath)) {
      return defaultFlutterPath;
    }

    print('Failed to find valid Dart SDK path');
    return null;
  }
}

class _StringLiteralVisitor extends RecursiveAstVisitor<void> {
  final List<String> strings = [];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _addString(node.literal.lexeme);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    for (final string in node.strings) {
      if (string is SimpleStringLiteral) {
        _addString(string.literal.lexeme);
      }
    }
    super.visitAdjacentStrings(node);
  }

  void _addString(String str) {
    if (str.length > 2 && !str.startsWith("'//") && !str.startsWith('"//')) {
      strings.add(str);
    }
  }
}