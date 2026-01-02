import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FightsStorage {
  static Future<Directory> _overlayDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, "obs-overlay"));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _file() async {
    final dir = await _overlayDir();
    return File(p.join(dir.path, "fights.json"));
  }

  static Future<List<Map<String, dynamic>>> _readList() async {
    final f = await _file();
    if (!await f.exists()) return [];

    try {
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      }
    } catch (_) {}

    return [];
  }

  /// Upserts by FightNumber (your requested structure)
  static Future<void> upsertFight({
    required int fightNumber,
    required String meronKey,
    required String walaKey,
    required String result, // "MeronWin" / "WalaWin" / "Draw" / "Cancel"
  }) async {
    final list = await _readList();

    final idx = list.indexWhere((m) => m["FightNumber"] == fightNumber);

    final entry = <String, dynamic>{
      "FightNumber": fightNumber,
      "MeronKey": meronKey,
      "WalaKey": walaKey,
      "Result": result,
    };

    if (idx >= 0) {
      list[idx] = {...list[idx], ...entry};
    } else {
      list.add(entry);
    }

    list.sort(
        (a, b) => (a["FightNumber"] as int).compareTo(b["FightNumber"] as int));

    final f = await _file();
    final pretty = const JsonEncoder.withIndent("  ").convert(list);
    await f.writeAsString(pretty, flush: true);
  }

  static Future<void> blank() async {
    final f = await _file();
    await f.writeAsString("[]", flush: true);
  }
}
