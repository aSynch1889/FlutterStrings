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
    'lib/generated',
    'test'
  ];

  // 检查是否是测试文件
  bool _isTestFile(String filePath) {
    return filePath.contains('_test.dart') || 
           filePath.contains('/test/') ||
           filePath.contains('\\test\\');
  }

  Future<Map<String, List<String>>> scanProject(
    String projectPath, {
    required String sdkPath,
    required void Function(int totalFiles) onStart,
    required void Function(String file, int scannedFiles) onProgress,
  }) async {
    final results = <String, List<String>>{};
    final excludedPaths = excludedFolders
        .map((folder) => join(projectPath, folder))
        .toList();

    // 验证 SDK 路径是否有效
    try {
      final libPath = join(sdkPath, 'lib');
      final metadataPath = join(libPath, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart');
      if (!await Directory(libPath).exists() || !await File(metadataPath).exists()) {
        throw Exception('配置的 SDK 路径无效，请检查设置中的 SDK 路径是否正确。');
      }
    } catch (e) {
      throw Exception('验证 SDK 路径时出错: $e');
    }

    print('Using configured SDK path: $sdkPath');

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
            .where((path) => !_isTestFile(path))
      );
    }

    // 通知总文件数
    onStart(allFiles.length);

    // 分析每个文件
    int scannedCount = 0;
    for (final context in collection.contexts) {
      final analyzedFiles = context.contextRoot.analyzedFiles()
          .where((path) => path.endsWith('.dart'))
          .where((path) => !excludedPaths.any((excluded) => path.startsWith(excluded)))
          .where((path) => !_isTestFile(path));

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
}

class _StringLiteralVisitor extends RecursiveAstVisitor<void> {
  final List<String> strings = [];
  bool _isInImportStatement = false;

  @override
  void visitImportDirective(ImportDirective node) {
    _isInImportStatement = true;
    super.visitImportDirective(node);
    _isInImportStatement = false;
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (!_isInImportStatement) {
      _addString(node.literal.lexeme);
    }
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    if (!_isInImportStatement) {
      for (final string in node.strings) {
        if (string is SimpleStringLiteral) {
          _addString(string.literal.lexeme);
        }
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