// 删除这行
// import 'dart:io';

// 保留其他必要的导入
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart';

class StringScanner {
  final List<String> excludedFolders = [
    'build',
    '.dart_tool',
    'packages',
    'ios',
    'android',
    'lib/generated'
  ];

  Future<Map<String, List<String>>> scanProject(String projectPath) async {
    final results = <String, List<String>>{};
    final excludedPaths = excludedFolders
        .map((folder) => join(projectPath, folder))
        .toList();

    final collection = AnalysisContextCollection(
      includedPaths: [projectPath],
      excludedPaths: excludedPaths,
    );

    for (final context in collection.contexts) {
      final analyzedFiles = context.contextRoot.analyzedFiles()
          .where((path) => path.endsWith('.dart'))
          .where((path) => !excludedPaths.any((excluded) => path.startsWith(excluded)));

      for (final filePath in analyzedFiles) {
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