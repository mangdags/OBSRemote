import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PresetsStorage {
  static Future<File> presetsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/obs-overlay/presets.json');
  }

  static Future<void> savePresetsJson(Map<String, dynamic> jsonMap) async {
    final f = await presetsFile();
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonMap));
  }

  static Future<Map<String, dynamic>> loadPresetsJson() async {
    final f = await presetsFile();
    if (!await f.exists()) return {};
    final txt = await f.readAsString();
    return jsonDecode(txt) as Map<String, dynamic>;
  }
}
