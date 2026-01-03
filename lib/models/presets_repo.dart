import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'fighter_preset.dart';

class PresetsRepo {
  static const int maxFights = 7;

  Future<File> _presetsFile() async {
    // Documents/obs-overlay/presets.json
    final docs = await getApplicationDocumentsDirectory();
    final baseOverlayDir = Directory(p.join(docs.path, "obs-overlay"));

    if (!await baseOverlayDir.exists()) {
      await baseOverlayDir.create(recursive: true);
    }

    return File(p.join(baseOverlayDir.path, "presets.json"));
  }

  Future<Map<String, dynamic>> _loadRawMap() async {
    final file = await _presetsFile();
    if (!await file.exists()) return {};

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    return {};
  }

  /// Existing method (unchanged behavior)
  Future<List<FighterPreset>> loadPresets() async {
    final decoded = await _loadRawMap();

    final list = <FighterPreset>[];
    decoded.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        list.add(FighterPreset.fromJson(key, value));
      }
    });

    list.sort(
      (a, b) => a.entryName.toLowerCase().compareTo(b.entryName.toLowerCase()),
    );
    return list;
  }

  Future<void> _saveRawMap(Map<String, dynamic> map) async {
    final file = await _presetsFile();
    final pretty = const JsonEncoder.withIndent("  ").convert(map);
    await file.writeAsString(pretty, flush: true);
  }

  /// ✅ NEW: Create or update preset from manual entry name
  Future<FighterPreset> upsertFromEntryName(String entryNameRaw) async {
    final entryName = entryNameRaw.trim();
    if (entryName.isEmpty) {
      throw ArgumentError("Entry name cannot be empty");
    }

    final key = _slugKey(entryName);
    final map = await _loadRawMap();

    Map<String, dynamic> presetJson;

    if (map.containsKey(key) && map[key] is Map<String, dynamic>) {
      // Preserve existing data
      presetJson = Map<String, dynamic>.from(map[key]);
    } else {
      // Create brand new preset
      presetJson = {
        "entry_name": entryName.toUpperCase(),
        "w": "",
        "wb": "",
        "notes": "",
        for (var i = 1; i <= maxFights; i++) "score_f$i": "",
      };
    }

    // Always update entry name (manual override)
    presetJson["entry_name"] = entryName.toUpperCase();

    map[key] = presetJson;

    final file = await _presetsFile();
    final pretty = const JsonEncoder.withIndent("  ").convert(map);
    await file.writeAsString(pretty, flush: true);

    return FighterPreset.fromJson(key, presetJson);
  }

  /// ✅ Update a single score field score_f{fightNo} for an existing preset key.
  /// value should be "1", "0", "0.5", or "" (blank).
  Future<void> setScore({
    required String presetKey,
    required int fightNo,
    required String value,
  }) async {
    if (fightNo < 1 || fightNo > maxFights) return;

    final map = await _loadRawMap();
    final existing = map[presetKey];

    if (existing is! Map) return; // key not found; ignore safely

    final presetJson = Map<String, dynamic>.from(existing as Map);
    presetJson["score_f$fightNo"] = value;

    map[presetKey] = presetJson;
    await _saveRawMap(map);
  }

  /// ✅ Convenience: update both fighters in one write.
  Future<void> setScoresForFight({
    required String meronKey,
    required String walaKey,
    required int fightNo,
    required String meronScore,
    required String walaScore,
  }) async {
    if (fightNo < 1 || fightNo > maxFights) return;

    final map = await _loadRawMap();

    void apply(String key, String val) {
      final existing = map[key];
      if (existing is! Map) return;
      final presetJson = Map<String, dynamic>.from(existing as Map);
      presetJson["score_f$fightNo"] = val;
      map[key] = presetJson;
    }

    apply(meronKey, meronScore);
    apply(walaKey, walaScore);

    await _saveRawMap(map);
  }

  /// ✅ Read one preset by key (for pushing scores to OBS)
  Future<FighterPreset?> getByKey(String presetKey) async {
    final map = await _loadRawMap();
    final v = map[presetKey];
    if (v is Map<String, dynamic>) return FighterPreset.fromJson(presetKey, v);
    if (v is Map)
      return FighterPreset.fromJson(presetKey, v.cast<String, dynamic>());
    return null;
  }

  /// madam kate -> madam_kate
  String _slugKey(String input) {
    var s = input.toLowerCase().trim();
    s = s.replaceAll(RegExp(r"\s+"), "_");
    s = s.replaceAll(RegExp(r"[^a-z0-9_]+"), "");
    s = s.replaceAll(RegExp(r"_+"), "_");
    s = s.replaceAll(RegExp(r"^_+|_+$"), "");
    return s.isEmpty ? "entry_${DateTime.now().millisecondsSinceEpoch}" : s;
  }

  int _nextEmptyScoreIndex(Map<String, dynamic> presetJson) {
    for (var i = 1; i <= maxFights; i++) {
      final v = (presetJson["score_f$i"] ?? "").toString().trim();
      if (v.isEmpty) return i;
    }
    // If full, just cap at maxFights (or throw, your choice)
    return maxFights;
  }

  Future<void> setScoresForNextAppearance({
    required String meronKey,
    required String walaKey,
    required String
        result, // "MeronWin" "WalaWin" "Draw" "Cancel" "MeronChamp" "WalaChamp"
  }) async {
    if (result == "Cancel") return;

    final map = await _loadRawMap();

    Map<String, dynamic>? getPreset(String key) {
      final existing = map[key];
      if (existing is Map<String, dynamic>)
        return Map<String, dynamic>.from(existing);
      if (existing is Map)
        return Map<String, dynamic>.from(existing.cast<String, dynamic>());
      return null;
    }

    final meronJson = getPreset(meronKey);
    final walaJson = getPreset(walaKey);

    if (meronJson == null || walaJson == null) return;

    // Determine values
    String meronScore = "";
    String walaScore = "";

    if (result == "MeronWin" || result == "MeronChamp") {
      meronScore = "1";
      walaScore = "0";
    } else if (result == "WalaWin" || result == "WalaChamp") {
      meronScore = "0";
      walaScore = "1";
    } else if (result == "Draw") {
      meronScore = "0.5";
      walaScore = "0.5";
    } else {
      return;
    }

    // ✅ find per-fighter next slot
    final meronIndex = _nextEmptyScoreIndex(meronJson);
    final walaIndex = _nextEmptyScoreIndex(walaJson);

    // ✅ write to each fighter's own next slot
    meronJson["score_f$meronIndex"] = meronScore;
    walaJson["score_f$walaIndex"] = walaScore;

    map[meronKey] = meronJson;
    map[walaKey] = walaJson;

    await _saveRawMap(map);
  }

  Future<void> setNotes({
    required String presetKey,
    required String notes,
  }) async {
    final map = await _loadRawMap();
    final existing = map[presetKey];
    if (existing is! Map) return;

    final presetJson = Map<String, dynamic>.from(existing as Map);
    presetJson["notes"] = notes;

    map[presetKey] = presetJson;
    await _saveRawMap(map);
  }
}
