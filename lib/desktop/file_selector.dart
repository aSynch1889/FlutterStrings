import 'package:file_selector/file_selector.dart' as file_selector;
import 'dart:typed_data';

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
}