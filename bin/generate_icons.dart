import 'package:flutter/widgets.dart';
import 'package:flutter_string_scanner/tools/generate_icon.dart';

void main() async {
  // 初始化 Flutter 绑定
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Generating app icons...');
  await generateIcons();
  print('Done!');
} 