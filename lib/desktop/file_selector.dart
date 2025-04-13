import 'package:file_selector/file_selector.dart' as fs;
import 'dart:typed_data';

class FileSelector {
  Future<String?> getDirectoryPath() async {
    return await fs.getDirectoryPath();
  }

  Future<String?> getSaveFilePath() async {
    final result = await fs.getSaveLocation(  // 修改这里
      suggestedName: 'strings_export.txt',
      acceptedTypeGroups: [
        const fs.XTypeGroup(
          label: 'Text files',
          extensions: ['txt'],
        ),
      ],
    );
    
    return result?.path;
  }

  Future<String?> saveFile(List<String> strings) async {
    final location = await fs.getSaveLocation();
    if (location == null) return null;
    
    const typeGroup = fs.XTypeGroup(
      label: 'Text Files',
      extensions: ['txt', 'csv'],
    );
    
    final file = fs.XFile.fromData(
      Uint8List.fromList(strings.join('\n').codeUnits),
      mimeType: 'text/plain',
      name: 'flutter_strings_${DateTime.now().toIso8601String()}.txt',
    );
    
    await file.saveTo(location.path);
    return location.path;  // 返回保存的文件路径
  }
}