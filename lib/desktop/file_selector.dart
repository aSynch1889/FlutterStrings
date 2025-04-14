import 'package:file_selector/file_selector.dart' as file_selector;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

class FileSelector {
  Future<String?> getDirectoryPath() async {
    try {
      final String? path = await file_selector.getDirectoryPath();
      return path;
    } catch (e) {
      print('Error selecting directory: $e');
      return null;
    }
  }

  Future<String?> getSaveFilePath() async {
    final result = await file_selector.getSaveLocation(
      suggestedName: 'strings_export.txt',
      acceptedTypeGroups: [
        const file_selector.XTypeGroup(
          label: 'Text files',
          extensions: ['txt'],
        ),
      ],
    );
    
    return result?.path;
  }

  Future<String?> saveFile(List<String> strings) async {
    final location = await file_selector.getSaveLocation();
    if (location == null) return null;
    
    final typeGroup = file_selector.XTypeGroup(
      label: 'Text Files',
      extensions: ['txt', 'csv'],
    );
    
    final file = file_selector.XFile.fromData(
      Uint8List.fromList(strings.join('\n').codeUnits),
      mimeType: 'text/plain',
      name: 'flutter_strings_${DateTime.now().toIso8601String()}.txt',
    );
    
    await file.saveTo(location.path);
    return location.path;
  }

  Future<String?> exportAsJson(Map<String, List<String>> results) async {
    final result = await file_selector.getSaveLocation(
      suggestedName: 'strings_export.json',
      acceptedTypeGroups: [
        const file_selector.XTypeGroup(
          label: 'JSON files',
          extensions: ['json'],
          mimeTypes: ['application/json'],
        ),
      ],
      initialDirectory: Platform.environment['HOME'],
      confirmButtonText: 'Save JSON',
    );
    
    if (result == null) {
      print('User cancelled file save dialog');
      return null;
    }

    print('Saving JSON file to: ${result.path}');

    // 将结果转换为 JSON 格式
    final jsonData = {
      'timestamp': DateTime.now().toIso8601String(),
      'project': results.keys.first.split('/').last,
      'totalFiles': results.length,
      'totalStrings': results.values.fold(0, (sum, strings) => sum + strings.length),
      'results': results.map((key, value) => MapEntry(
        key,
        value.map((str) => {
          'value': str,
          'length': str.length,
          'isMultiline': str.contains('\n'),
        }).toList(),
      )),
    };

    // 使用 UTF-8 编码并确保中文字符正确显示
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    final bytes = utf8.encode(jsonString);
    final file = file_selector.XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'application/json; charset=utf-8',
      name: 'flutter_strings_${DateTime.now().toIso8601String()}.json',
    );
    
    try {
      await file.saveTo(result.path);
      print('Successfully saved JSON file');
      return result.path;
    } catch (e) {
      print('Error saving JSON file: $e');
      rethrow;
    }
  }

  Future<String?> exportAsCsv(Map<String, List<String>> results) async {
    final result = await file_selector.getSaveLocation(
      suggestedName: 'strings_export.csv',
      acceptedTypeGroups: [
        const file_selector.XTypeGroup(
          label: 'CSV files',
          extensions: ['csv'],
          mimeTypes: ['text/csv'],
        ),
      ],
      initialDirectory: Platform.environment['HOME'],
      confirmButtonText: 'Save CSV',
    );
    
    if (result == null) {
      print('User cancelled file save dialog');
      return null;
    }

    print('Saving CSV file to: ${result.path}');

    // 构建 CSV 内容
    final csvRows = <List<String>>[];
    
    // 添加表头
    csvRows.add(['File Path', 'String Value', 'Length', 'Is Multiline']);
    
    // 添加数据行
    results.forEach((filePath, strings) {
      for (final str in strings) {
        csvRows.add([
          filePath,
          str,
          str.length.toString(),
          str.contains('\n').toString(),
        ]);
      }
    });

    // 将数据转换为 CSV 格式
    final csvContent = csvRows.map((row) => row.map((cell) {
      // 处理包含逗号、引号或换行符的单元格
      if (cell.contains(',') || cell.contains('"') || cell.contains('\n')) {
        return '"${cell.replaceAll('"', '""')}"';
      }
      return cell;
    }).join(',')).join('\n');

    // 使用 UTF-8 编码并确保中文字符正确显示
    final bytes = utf8.encode(csvContent);
    final file = file_selector.XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'text/csv; charset=utf-8',
      name: 'flutter_strings_${DateTime.now().toIso8601String()}.csv',
    );
    
    try {
      await file.saveTo(result.path);
      print('Successfully saved CSV file');
      return result.path;
    } catch (e) {
      print('Error saving CSV file: $e');
      rethrow;
    }
  }

  Future<String?> exportAsArb(Map<String, List<String>> results) async {
    final result = await file_selector.getSaveLocation(
      suggestedName: 'app_en.arb',
      acceptedTypeGroups: [
        const file_selector.XTypeGroup(
          label: 'ARB files',
          extensions: ['arb'],
          mimeTypes: ['application/json'],
        ),
      ],
      initialDirectory: Platform.environment['HOME'],
      confirmButtonText: 'Save ARB',
    );
    
    if (result == null) {
      print('User cancelled file save dialog');
      return null;
    }

    print('Saving ARB file to: ${result.path}');

    // 构建 ARB 内容
    final arbData = <String, dynamic>{
      '@@locale': 'en',
      '@@last_modified': DateTime.now().toIso8601String(),
    };

    // 为每个字符串生成唯一的 key
    int counter = 0;
    results.forEach((filePath, strings) {
      for (final str in strings) {
        // 生成基于文件路径和字符串内容的 key
        final key = 'string_${filePath.split('/').last.replaceAll('.dart', '')}_${counter++}';
        arbData[key] = str;
        
        // 添加描述信息
        arbData['@$key'] = {
          'description': 'String from ${filePath.split('/').last}',
          'type': 'text',
          'placeholders': {},
        };
      }
    });

    // 将数据转换为 JSON 格式
    final jsonString = const JsonEncoder.withIndent('  ').convert(arbData);
    final bytes = utf8.encode(jsonString);
    final file = file_selector.XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'application/json; charset=utf-8',
      name: 'app_en.arb',
    );
    
    try {
      await file.saveTo(result.path);
      print('Successfully saved ARB file');
      return result.path;
    } catch (e) {
      print('Error saving ARB file: $e');
      rethrow;
    }
  }
}