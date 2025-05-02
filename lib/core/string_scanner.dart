import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'config.dart';

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
      throw Exception('Cannot find Dart SDK path. Please configure the SDK path in settings.');
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

  Future<String?> _getDartSdkPath() async {
    // 1. 首先尝试从配置文件获取
    final config = AppConfig();
    await config.loadConfig();
    if (config.dartSdkPath != null) {
      print('Using configured SDK path: ${config.dartSdkPath}');
      if (await _isValidSdkPath(config.dartSdkPath!)) {
        return config.dartSdkPath;
      }
    }

    // 2. 如果配置文件中的路径无效，尝试其他方法
    return await _findDefaultSdkPath();
  }

  Future<bool> _isValidSdkPath(String path) async {
    try {
      final libPath = join(path, 'lib');
      final metadataPath = join(libPath, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart');
      final isValid = await Directory(libPath).exists() && await File(metadataPath).exists();
      if (isValid) {
        print('Found valid Dart SDK at: $path');
      } else {
        print('Invalid SDK path: $path');
      }
      return isValid;
    } catch (e) {
      print('Error validating SDK path: $e');
      return false;
    }
  }

  Future<String?> _findDefaultSdkPath() async {
    // 验证 SDK 路径是否有效
    bool isValidSdkPath(String path) {
      try {
        final libPath = join(path, 'lib');
        final metadataPath = join(libPath, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart');
        final isValid = Directory(libPath).existsSync() && File(metadataPath).existsSync();
        if (isValid) {
          print('Found valid Dart SDK at: $path');
        }
        return isValid;
      } catch (e) {
        print('Error validating SDK path: $e');
        return false;
      }
    }

    // 1. 首先尝试从 Flutter 环境变量获取
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final dartSdkPath = join(flutterRoot, 'bin', 'cache', 'dart-sdk');
      print('Checking Flutter environment path: $dartSdkPath');
      if (isValidSdkPath(dartSdkPath)) {
        return dartSdkPath;
      }
    }

    // 2. 尝试从 which flutter 命令获取
    try {
      final whichResult = Process.runSync('which', ['flutter']);
      if (whichResult.exitCode == 0) {
        final flutterPath = whichResult.stdout.toString().trim();
        if (flutterPath.isNotEmpty) {
          final flutterDir = Directory(flutterPath).parent.parent;
          final dartSdkPath = join(flutterDir.path, 'bin', 'cache', 'dart-sdk');
          print('Checking which flutter path: $dartSdkPath');
          if (isValidSdkPath(dartSdkPath)) {
            return dartSdkPath;
          }
        }
      }
    } catch (e) {
      print('Error getting Flutter path from which command: $e');
    }

    // 3. 尝试从 Flutter SDK 路径获取
    try {
      final flutterSdkPath = Platform.environment['FLUTTER_SDK'];
      if (flutterSdkPath != null) {
        final dartSdkPath = join(flutterSdkPath, 'bin', 'cache', 'dart-sdk');
        print('Checking Flutter SDK path: $dartSdkPath');
        if (isValidSdkPath(dartSdkPath)) {
          return dartSdkPath;
        }
      }
    } catch (e) {
      print('Error getting Flutter SDK path: $e');
    }

    // 4. 尝试从应用沙盒目录获取
    try {
      final appSupportDir = Platform.environment['HOME'];
      if (appSupportDir != null) {
        final dartSdkPath = join(appSupportDir, 'development', 'flutter', 'bin', 'cache', 'dart-sdk');
        print('Checking app sandbox path: $dartSdkPath');
        if (isValidSdkPath(dartSdkPath)) {
          return dartSdkPath;
        }
      }
    } catch (e) {
      print('Error getting app sandbox path: $e');
    }

    print('Failed to find valid Dart SDK path. Please configure the SDK path in settings.');
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