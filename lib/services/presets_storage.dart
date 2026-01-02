import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PresetsStorage {
  static Future<Directory> _overlayDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/obs-overlay');
  }

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

  static Future<void> archiveAndBlankEventFiles() async {
    final dir = await _overlayDir();

    final filesToHandle = {
      "fights.js",
      "fights.json",
      "presets.json",
    };

    final archiveRoot = Directory(p.join(dir.path, "archive"));
    if (!await archiveRoot.exists()) {
      await archiveRoot.create(recursive: true);
    }

    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(":", "-")
        .replaceAll(".", "-");

    final archiveDir = Directory(p.join(archiveRoot.path, stamp));
    await archiveDir.create(recursive: true);

    for (final name in filesToHandle) {
      final file = File(p.join(dir.path, name));
      if (!await file.exists()) continue;

      // archive
      await file.copy(p.join(archiveDir.path, name));

      // blank content safely
      if (name.endsWith(".json")) {
        await file.writeAsString("{}", flush: true);
      } else if (name.endsWith(".js")) {
        await file.writeAsString(
          "// reset for next event\n",
          flush: true,
        );
      }
    }
  }
}
