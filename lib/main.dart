import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obsremote/models/presets_repo.dart';
import 'package:obsremote/scores_overview_screen.dart';
import 'package:obsremote/services/fights_storage.dart';
import 'package:obsremote/widgets/entry_name.dart';
import 'package:obsremote/widgets/fight_info.dart';
import 'package:obsremote/widgets/scenes.dart';
import 'package:obsremote/widgets/winning_sides.dart';
import 'package:obsremote/models/fighter_preset.dart';
import 'obs_client.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'services/docx_importer.dart';
import 'services/presets_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // WindowManager.instance.setTitleBarStyle(TitleBarStyle.hidden);
    WindowManager.instance.setTitle('OBS Remote');
    WindowManager.instance.setMinimumSize(const Size(1055, 700));
    // WindowManager.instance.setMaximumSize(const Size(1070, 700));
  }
  runApp(const ObsRemoteApp());
}

class ObsRemoteApp extends StatelessWidget {
  const ObsRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OBS Remote',
      theme: ThemeData(useMaterial3: true),
      home: const ObsRemoteHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ObsRemoteHome extends StatefulWidget {
  const ObsRemoteHome({super.key});
  @override
  State<ObsRemoteHome> createState() => _ObsRemoteHomeState();
}

class _ObsRemoteHomeState extends State<ObsRemoteHome> {
  final _obs = ObsClient();

  final _hostCtrl =
      TextEditingController(text: "192.168.1.6"); // <-- OBS PC IP
  final _entryCtrl = TextEditingController();

  String _side = "meron";
  String _status = "Disconnected";
  bool get _connected => _obs.isConnected;

  // your OBS names
  final String fightSceneName = "2 HITS RIGHT CAM";
  final String meronTextSource = "MeronEntryName";
  final String walaTextSource = "WalaEntryName";
  final String meronBanner = "MeronBanner";
  final String walaBanner = "WalaBanner";
  late String meronEntryName = "";
  late String walaEntryName = "";

  final String meronWeight = "meron_weight";
  final String walaWeight = "wala_weight";
  final String meronWB = "meron_wb";
  final String walaWB = "wala_wb";

  Duration showDuration = const Duration(seconds: 7);
  Duration preShowDelay =
      const Duration(milliseconds: 250); // name “loads” first

  // winner flow state
  int currentFightNo = 1;
  String? defaultSceneKey; // from dropdown in Scenes
  final scenesKey = GlobalKey<ScenesState>();

  String meronKey = "";
  String walaKey = "";

  // OBS scenes (edit to your real scene names)
  final String replaySceneName = "SceneReplay";
  final String meronWinScene = "MERON-WINS";
  final String walaWinScene = "WALA-WINS";
  final String drawScene = "DRAW-FIGHT";
  final String cancelScene = "CANCELLED-FIGHT";
  final String meronChampScene = "MERON-CHAMP";
  final String walaChampScene = "WALA-CHAMP";

  Timer? _winnerTimer;
  Timer? _replayTimer;

  final _presetsRepo = PresetsRepo();

  void _cancelWinnerFlow() {
    _winnerTimer?.cancel();
    _replayTimer?.cancel();
    _winnerTimer = null;
    _replayTimer = null;
  }

  String wrapEntryNameMulti(
    String name, {
    int maxCharsPerLine = 30,
    int maxLines = 3,
  }) {
    final text = name.trim();
    if (text.isEmpty) return text;

    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];

    var current = '';

    for (final word in words) {
      final next = current.isEmpty ? word : '$current $word';

      if (next.length <= maxCharsPerLine) {
        current = next;
      } else {
        lines.add(current);
        current = word;

        if (lines.length == maxLines - 1) {
          break;
        }
      }
    }

    if (lines.length < maxLines && current.isNotEmpty) {
      lines.add(current);
    }

    // If text still remains, append it to last line (trimmed)
    final usedWords = lines.join(' ').split(RegExp(r'\s+')).length;
    if (usedWords < words.length) {
      final remaining = words.sublist(usedWords).join(' ');
      lines[lines.length - 1] = '${lines.last} ${remaining}'.trim();
    }

    return lines.join('\n');
  }

  static const int maxFights = FighterPreset.maxFights;

  String meronScoreSource(int i) => "meron_score_$i";
  String walaScoreSource(int i) => "wala_score_$i";

  final String meronScoresGroup = "MeronScoresGroup";
  final String walaScoresGroup = "WalaScoresGroup";

  FighterPreset? _meronPreset;
  FighterPreset? _walaPreset;

  late String scoresSceneName;

  bool _meronScoresVisible = false;
  bool _walaScoresVisible = false;

  List<String> _labelsFromPreset(FighterPreset? p, int fightsToShow) {
    if (p == null) {
      return List.generate(fightsToShow, (i) => "F${i + 1}: ");
    }

    return List.generate(fightsToShow, (i) {
      final idx = i + 1;
      final s = (p.scores[idx] ?? "").trim();
      return "F$idx: ${s.isEmpty ? "" : s}";
    });
  }

  Future<void> _pushScoresToObs({
    required bool isMeron,
    required FighterPreset fighterPreset,
  }) async {
    if (!_obs.isConnected) return;

    debugPrint("PUSH ${fighterPreset.key} scores: ${fighterPreset.scores}");

    for (var i = 1; i <= maxFights; i++) {
      final val = fighterPreset.scores[i] ?? ""; // ✅ real stored values
      final inputName = isMeron ? meronScoreSource(i) : walaScoreSource(i);

      await _obs.setTextSource(inputName: inputName, text: val);
    }
  }

  Future<void> _setScoresVisibility(
      {required bool showMeron, required bool showWala}) async {
    if (!_obs.isConnected) return;

    try {
      await _obs.setSceneItemVisibleByName(
        sceneName: scoresSceneName,
        sourceName: meronScoresGroup,
        visible: showMeron,
      );
      await _obs.setSceneItemVisibleByName(
        sceneName: scoresSceneName,
        sourceName: walaScoresGroup,
        visible: showWala,
      );

      _meronScoresVisible = showMeron;
      _walaScoresVisible = showWala;
    } catch (_) {}
  }

  // Convenience:
  Future<void> _hideAllScores() =>
      _setScoresVisibility(showMeron: false, showWala: false);

  Future<void> _updateScoresVisibilityAfterSelection() async {
    // Show only the sides that currently have keys set
    final showMeron = meronKey.isNotEmpty;
    final showWala = walaKey.isNotEmpty;
    await _setScoresVisibility(showMeron: showMeron, showWala: showWala);
  }

  void snack(String msg, {bool isError = false}) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  Future<void> _connect() async {
    //setState(() => _status = "Connecting...");
    try {
      await _obs.connect(host: _hostCtrl.text.trim(), port: 4455);
      setState(() => _status = "Connected");
    } catch (e) {
      setState(() => _status = "Connect failed: $e");
    }
  }

  Future<void> _sendEntry() async {
    if (!_obs.isConnected) {
      setState(() => _status = "Not connected");
      return;
    }

    final name = _entryCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _status = "Type an entry name first");
      return;
    }

    try {
      // 1) Update the text source first
      if (_side == "meron") {
        await _obs.setTextSource(inputName: meronTextSource, text: name);
      } else {
        await _obs.setTextSource(inputName: walaTextSource, text: name);
      }

      // 2) Delay so OBS applies the source text before showing banner
      await Future.delayed(preShowDelay);

      // 3) Show banner source inside fight scene
      await _obs.showEntryBanner(
        fightSceneName: fightSceneName,
        bannerSourceName: _side == "meron" ? meronBanner : walaBanner,
        duration: showDuration,
      );

      setState(() => _status = "Shown: ${_side.toUpperCase()} - $name");
    } catch (e) {
      setState(() => _status = "Error: $e");
    }
  }

  Future<void> importDocx(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      withData: true, // important (gets bytes on most platforms)
    );

    if (res == null) return; // cancelled

    final bytes = res.files.single.bytes;
    if (bytes == null) {
      // fallback to path read
      final path = res.files.single.path;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read DOCX bytes/path')),
        );
        return;
      }
      final fileBytes = await File(path).readAsBytes();
      await _importBytes(context, fileBytes);
      return;
    }

    await _importBytes(context, bytes);
  }

  Future<void> _importBytes(BuildContext context, List<int> bytes) async {
    try {
      final result = DocxImporter.importFromBytes(bytes as Uint8List);

      // Convert to your presets.json structure
      final jsonMap = <String, dynamic>{};
      for (final e in result.presets.entries) {
        jsonMap[e.key] = e.value.toJson();
      }

      await PresetsStorage.savePresetsJson(jsonMap);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${jsonMap.length} fighters (${result.looksLikeNewFormat ? "NEW" : "OLD"} format)',
          ),
        ),
      );
      setState(() {
        meronEntryName = "";
        walaEntryName = "";
      });
      await entryNameKey.currentState?.refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  final entryNameKey = GlobalKey<EntryNameState>();

  Future<void> _applyScoresFromResult({
    required String
        result, // "MeronWin" "WalaWin" "Draw" "Cancel" "MeronChamp" "WalaChamp"
    required int fightNo,
    required String meronKey,
    required String walaKey,
  }) async {
    // Cancel = do nothing (recommended)
    if (result == "Cancel") return;

    // ignore: unused_local_variable
    String meronScore = "";
    // ignore: unused_local_variable
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

    await _presetsRepo.setScoresForNextAppearance(
      meronKey: meronKey,
      walaKey: walaKey,
      result: result,
    );

    // Reload updated presets and push to OBS
    final m = await _presetsRepo.getByKey(meronKey);
    final w = await _presetsRepo.getByKey(walaKey);

    if (m != null) await _pushScoresToObs(isMeron: true, fighterPreset: m);
    if (w != null) await _pushScoresToObs(isMeron: false, fighterPreset: w);

    await entryNameKey.currentState?.refresh();
  }

  //WINNER SCENE
  Future<void> setWinnerAndPlayFlow(String result) async {
    // result must be: "MeronWin", "WalaWin", "Draw", "Cancel"
    _cancelWinnerFlow();

    if (meronKey.isEmpty || walaKey.isEmpty) {
      snack("Set Meron/Wala first (keys missing).", isError: true);
      return;
    }
    if (defaultSceneKey == null || defaultSceneKey!.isEmpty) {
      snack("Select Default Scene first.", isError: true);
      return;
    }

    // 1) Save fights.json (your requested format)
    await FightsStorage.upsertFight(
      fightNumber: currentFightNo,
      meronKey: meronKey,
      walaKey: walaKey,
      result: result,
    );

    if (!_obs.isConnected) {
      setState(() => _status = "Saved result, but OBS not connected");
      snack("Saved fights.json, but OBS not connected.", isError: true);
      return;
    }

    // 2) Play winner scene
    String winnerScene;
    switch (result) {
      case "MeronWin":
        winnerScene = meronWinScene;
        break;
      case "WalaWin":
        winnerScene = walaWinScene;
        break;
      case "Draw":
        winnerScene = drawScene;
        break;
      case "Cancel":
        winnerScene = cancelScene;
        break;
      case "MeronChamp":
        winnerScene = meronChampScene;
        break;
      case "WalaChamp":
        winnerScene = walaChampScene;
        break;
      default:
        snack("Unknown result: $result", isError: true);
        return;
    }

    try {
      await _obs.setCurrentProgramScene(winnerScene);
      setState(
          () => _status = "Fight $currentFightNo -> $result ($winnerScene)");
    } catch (e) {
      snack("Failed to switch to winner scene: $e", isError: true);
      return;
    }

    // 3) After 30s, play replay scene
    _winnerTimer = Timer(const Duration(seconds: 10), () async {
      if (!_obs.isConnected) return;
      try {
        await _obs.setCurrentProgramScene(replaySceneName);
        setState(() => _status = "Replay -> $replaySceneName");

        // 4) After 10s, go back to default scene
        _replayTimer = Timer(const Duration(seconds: 10), () async {
          if (!_obs.isConnected) return;

          try {
            await _obs.setCurrentProgramScene(defaultSceneKey!);

            await _updateScoresVisibilityAfterSelection();

            await _applyScoresFromResult(
              result: result,
              fightNo: currentFightNo,
              meronKey: meronKey,
              walaKey: walaKey,
            );

            // ✅ AUTO-INCREMENT FIGHT NUMBER
            setState(() {
              currentFightNo += 1;
              _status = "Fight complete. Ready for Fight $currentFightNo";
            });

            // ✅ Update Scenes TextField + OBS source
            await scenesKey.currentState?.setFightNumber(currentFightNo);

            // ✅ CLEAR ENTRY NAMES (OBS + UI)
            await _clearObsEntryNames();
            await _hideAllScores();
            _clearLocalEntryState();
          } catch (e) {
            snack("Failed to return to default: $e", isError: true);
          }
        });
      } catch (e) {
        snack("Failed to play replay scene: $e", isError: true);
      }
    });
  }

  Future<void> _clearObsEntryNames() async {
    if (!_obs.isConnected) return;

    try {
      await _obs.setTextSource(inputName: meronTextSource, text: "");
      await _obs.setTextSource(inputName: walaTextSource, text: "");

      await _obs.setTextSource(inputName: meronWeight, text: "");
      await _obs.setTextSource(inputName: meronWB, text: "");
      await _obs.setTextSource(inputName: walaWeight, text: "");
      await _obs.setTextSource(inputName: walaWB, text: "");
    } catch (_) {
      // swallow errors silently (end-of-flow cleanup)
    }
  }

  Future<void> _clearObsScores() async {
    if (!_obs.isConnected) return;

    try {
      for (int x = 1; x <= maxFights; x++) {
        await _obs.setTextSource(inputName: "meron_score_$x", text: "");
        await _obs.setTextSource(inputName: "wala_score_$x", text: "");
      }
    } catch (_) {
      // swallow errors silently (end-of-flow cleanup)
    }
  }

  void _clearLocalEntryState() {
    setState(() {
      meronEntryName = "";
      walaEntryName = "";
      meronKey = "";
      walaKey = "";
    });

    // clears dropdown selection + manual fields
    entryNameKey.currentState?.clearInputsOnly();
  }

  String manualKey(String name) {
    final s = name.trim().toLowerCase().replaceAll(RegExp(r"\s+"), "_");
    final cleaned = s.replaceAll(RegExp(r"[^a-z0-9_]+"), "");
    return cleaned.isEmpty ? "manual" : "manual_$cleaned";
  }

  //END

  Future<FighterPreset> _freshPreset(FighterPreset p) async {
    final latest = await _presetsRepo.getByKey(p.key);
    return latest ?? p;
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _entryCtrl.dispose();
    _obs.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _connect();
    return Scaffold(
      appBar: AppBar(
        title: const Text("OBS Remote"),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('OBS Remote Settings')),
            ListTile(
              title: const Text('Scores Overview'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ScoresOverviewScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Import DOCX'),
              onTap: () async {
                Navigator.pop(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Import new set?"),
                    content: const Text(
                      "This will append to the current list",
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel")),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Import")),
                    ],
                  ),
                );

                if (ok == true) {
                  importDocx(context);
                }
              },
            ),
            ListTile(
              title: const Text('Import CSV'),
              onTap: () async {
                Navigator.pop(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Import new set?"),
                    content: const Text(
                      "This will append to the current list",
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel")),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Import")),
                    ],
                  ),
                );

                if (ok == true) {
                  importDocx(context);
                  await entryNameKey.currentState?.refresh();

                  setState(() {
                    meronEntryName = "";
                    walaEntryName = "";
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Import Success!')),
                    );
                  });
                }
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Reset'),
              onTap: () async {
                Navigator.pop(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Reset for next event?"),
                    content: const Text(
                      "This will archive and clear fights.js, fights.json, and presets.json.",
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel")),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Reset")),
                    ],
                  ),
                );

                if (ok == true) {
                  await PresetsStorage.archiveAndBlankEventFiles();
                  await entryNameKey.currentState?.refresh();

                  setState(() {
                    meronEntryName = "";
                    walaEntryName = "";
                    meronKey = "";
                    walaKey = "";
                    currentFightNo = 1;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset Success!')),
                    );
                  });
                }
              },
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            EntryName(
                key: entryNameKey,
                title: "Entry Name Setter",
                onSetMeron: (preset) async {
                  final displayName = wrapEntryNameMulti(preset.entryName,
                      maxCharsPerLine: 50, maxLines: 4);

                  final fresh = await _freshPreset(
                      preset); // ✅ reload latest scores from file

                  await _obs.setTextSource(
                      inputName: meronTextSource, text: displayName);
                  await _obs.setTextSource(
                      inputName: meronWeight, text: fresh.w);
                  await _obs.setTextSource(inputName: meronWB, text: fresh.wb);

                  await _pushScoresToObs(isMeron: true, fighterPreset: fresh);

                  setState(() {
                    _meronPreset = fresh;
                    _status = "MERON set: ${fresh.entryName}";
                    meronEntryName = fresh.entryName;
                    meronKey = fresh.key;
                  });

                  await _updateScoresVisibilityAfterSelection();

                  await Future.delayed(preShowDelay);
                  await _obs.showEntryBanner(
                    fightSceneName: fightSceneName,
                    bannerSourceName: meronBanner,
                    duration: showDuration,
                  );
                },
                onSetWala: (preset) async {
                  final fresh = await _freshPreset(preset);
                  final displayName = wrapEntryNameMulti(preset.entryName,
                      maxCharsPerLine: 50, maxLines: 4);

                  await _obs.setTextSource(
                      inputName: walaTextSource, text: displayName);
                  await _obs.setTextSource(
                      inputName: walaWeight, text: fresh.w);
                  await _obs.setTextSource(inputName: walaWB, text: fresh.wb);

                  await _pushScoresToObs(isMeron: false, fighterPreset: fresh);

                  setState(() {
                    _walaPreset = fresh;
                    _status = "WALA set: ${fresh.entryName}";
                    walaEntryName = fresh.entryName;
                    walaKey = fresh.key;
                  });

                  await _updateScoresVisibilityAfterSelection();

                  await Future.delayed(preShowDelay);
                  await _obs.showEntryBanner(
                    fightSceneName: fightSceneName,
                    bannerSourceName: walaBanner,
                    duration: showDuration,
                  );
                },
                onUseManualMeron: (meronName) async {
                  if (meronName.isNotEmpty) {
                    final displayName = wrapEntryNameMulti(meronName,
                        maxCharsPerLine: 50, maxLines: 4);
                    await _obs.setTextSource(
                        inputName: meronTextSource, text: displayName);
                    await _obs.setTextSource(
                        inputName: meronWeight, text: "--");
                    await _obs.setTextSource(
                        inputName: meronWB, text: "ULUTAN");

                    setState(() {
                      meronEntryName = meronName;
                      meronKey = manualKey(meronName);
                    });

                    final preset =
                        await PresetsRepo().upsertFromEntryName(meronName);
                    setState(() {
                      meronEntryName = preset.entryName;
                      meronKey = preset.key;
                    });

                    await _updateScoresVisibilityAfterSelection();

                    await _pushScoresToObs(
                        isMeron: true, fighterPreset: preset);

                    await Future.delayed(preShowDelay);
                    await _obs.showEntryBanner(
                      fightSceneName: fightSceneName,
                      bannerSourceName: meronBanner,
                      duration: showDuration,
                    );
                  }
                },
                onUseManualWala: (walaName) async {
                  if (walaName.isNotEmpty) {
                    final displayName = wrapEntryNameMulti(walaName,
                        maxCharsPerLine: 50, maxLines: 4);
                    await _obs.setTextSource(
                        inputName: walaTextSource, text: displayName);
                    await _obs.setTextSource(inputName: walaWeight, text: "--");
                    await _obs.setTextSource(inputName: walaWB, text: "ULUTAN");

                    setState(() {
                      walaEntryName = walaName;
                      walaKey = manualKey(walaName);
                    });

                    final preset =
                        await PresetsRepo().upsertFromEntryName(walaName);
                    setState(() {
                      walaEntryName = preset.entryName;
                      walaKey = preset.key;
                    });

                    await _updateScoresVisibilityAfterSelection();

                    await _pushScoresToObs(
                        isMeron: false, fighterPreset: preset);

                    await Future.delayed(preShowDelay);
                    await _obs.showEntryBanner(
                      fightSceneName: fightSceneName,
                      bannerSourceName: walaBanner,
                      duration: showDuration,
                    );
                  }
                }),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                // Example: set OBS text + show banner using your existing ObsClient functions
                FightInfo(
                  numberOfFights: 7,
                  entryName: meronEntryName,
                  backgroundColor: Colors.redAccent,
                  presetKey: _meronPreset?.key ?? "",
                  scores: _meronPreset?.scores ?? const {},
                  onScoreChanged: (fightIndex, value) async {
                    if (_meronPreset == null) return;

                    await _presetsRepo.setScore(
                      presetKey: _meronPreset!.key,
                      fightNo: fightIndex,
                      value: value,
                    );

                    // reload fresh + update OBS + update UI
                    final fresh =
                        await _presetsRepo.getByKey(_meronPreset!.key);
                    if (fresh != null) {
                      setState(() => _meronPreset = fresh);
                      await _pushScoresToObs(
                          isMeron: true, fighterPreset: fresh);
                    }
                  },
                ),

                const SizedBox(width: 12),
                FightInfo(
                  numberOfFights: 7,
                  entryName: walaEntryName,
                  backgroundColor: Colors.blueAccent,
                  presetKey: _walaPreset?.key ?? "",
                  scores: _walaPreset?.scores ?? const {},
                  onScoreChanged: (fightIndex, value) async {
                    if (_walaPreset == null) return;

                    await _presetsRepo.setScore(
                      presetKey: _walaPreset!.key,
                      fightNo: fightIndex,
                      value: value,
                    );

                    final fresh = await _presetsRepo.getByKey(_walaPreset!.key);
                    if (fresh != null) {
                      setState(() => _walaPreset = fresh);
                      await _pushScoresToObs(
                          isMeron: false, fighterPreset: fresh);
                    }
                  },
                ),

                const SizedBox(width: 12),
                WinningSides(
                  onPickResult: (result) async {
                    await setWinnerAndPlayFlow(result);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Scenes(
              key: scenesKey,
              obs: _obs,
              onDefaultSceneChanged: (v) async {
                defaultSceneKey = v;
                scoresSceneName = v!;

                await _updateScoresVisibilityAfterSelection();
              },
              onFightNumberChanged: (n) {
                setState(() {
                  currentFightNo = n;
                });
              },
            ),
            const SizedBox(height: 12),
            const Divider(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Status: $_status",
              style: TextStyle(fontSize: 18),
            ),
            IconButton(
              onPressed: _connect,
              icon: const Icon(Icons.refresh),
              tooltip: _obs.isConnected ? "Connected" : "Disconnected",
              color: _obs.isConnected ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
