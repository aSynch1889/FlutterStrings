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
}