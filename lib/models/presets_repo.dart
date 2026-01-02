import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'fighter_preset.dart';

class PresetsRepo {
  Future<File> _presetsFile() async {
    // Documents/obs-overlay/presets.json
    final docs = await getApplicationDocumentsDirectory();
    final baseOverlayDir = Directory(p.join(docs.path, "obs-overlay"));
    return File(p.join(baseOverlayDir.path, "presets.json"));
  }

  Future<List<FighterPreset>> loadPresets() async {
    final file = await _presetsFile();
    if (!await file.exists()) return [];

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) return [];

    final list = <FighterPreset>[];
    decoded.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        list.add(FighterPreset.fromJson(key, value));
      }
    });

    list.sort((a, b) => a.entryName.toLowerCase().compareTo(b.entryName.toLowerCase()));
    return list;
  }
}
