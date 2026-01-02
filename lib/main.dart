import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obsremote/widgets/entry_name.dart';
import 'package:obsremote/widgets/fight_info.dart';
import 'package:obsremote/widgets/manual_score.dart';
import 'package:obsremote/widgets/scenes.dart';
import 'package:obsremote/widgets/winning_sides.dart';
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

  final _hostCtrl = TextEditingController(text: "10.68.182.166"); // <-- OBS PC IP
  final _entryCtrl = TextEditingController();

  String _side = "meron";
  String _status = "Disconnected";
  bool get _connected => _obs.isConnected;

  // your OBS names
  final String fightSceneName = "2 HITS RIGHT CAM";
  final String meronTextSource = "MeronEntryName";
  final String walaTextSource = "WalaEntryName";
  final String meronBanner = "MeronBanner";
  final String walaBanner  = "WalaBanner";
  late String meronEntryName ="";
  late String walaEntryName ="";

  final String meronWeight = "meron_weight";
  final String walaWeight ="wala_weight";
  final String meronWB = "meron_wb";
  final String walaWB = "wala_wb";

  Duration showDuration = const Duration(seconds: 7);
  Duration preShowDelay = const Duration(milliseconds: 250); // name “loads” first

  Future<void> _connect() async {
    setState(() => _status = "Connecting...");
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

    // TODO: refresh your dropdown list by reloading presets.json into state
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import failed: $e')),
    );
  }
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
    return Scaffold(
      appBar: AppBar(title: const Text("OBS Remote"), leading: Builder(builder: (context) {
        return IconButton(icon: const Icon(Icons.menu), onPressed: () {
          Scaffold.of(context).openDrawer();
        },);
      }),),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('OBS Remote Settings')),
            ListTile(
              title: const Text('Import DOCX'),
              onTap: () {
                Navigator.pop(context);
                importDocx(context);
              },
            ),
            ListTile(
              title: const Text('Import CSV'),
              onTap: () {

                Navigator.pop(context);
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
              title: "Entry Name Setter",
              onSetMeron: (preset) async {
                // Example: set OBS text + show banner using your existing ObsClient functions
                await _obs.setTextSource(inputName: meronTextSource, text: preset.entryName);
                await _obs.setTextSource(inputName: meronWeight, text: preset.w);
                await _obs.setTextSource(inputName: meronWB, text: preset.wb);
                
                setState(() => _status = "MERON set: ${preset.entryName}");
                setState(() {
                  meronEntryName = preset.entryName;
                });

                await Future.delayed(preShowDelay);
                await _obs.showEntryBanner(
                  fightSceneName: fightSceneName,
                  bannerSourceName: meronBanner,
                  duration: showDuration,
                );

                 
              },
              onSetWala: (preset) async {
                await _obs.setTextSource(inputName: walaTextSource, text: preset.entryName);
                await _obs.setTextSource(inputName: walaWeight, text: preset.w);
                await _obs.setTextSource(inputName: walaWB, text: preset.wb);
                
                setState(() => _status = "WALA set: ${preset.entryName}");
                setState(() {
                  walaEntryName = preset.entryName;
                });

                await Future.delayed(preShowDelay);
                await _obs.showEntryBanner(
                  fightSceneName: fightSceneName,
                  bannerSourceName: walaBanner,
                  duration: showDuration,
                );

                 
              },

              onUseManualMeron: (meronName) async {
                if (meronName.isNotEmpty) {
                  await _obs.setTextSource(inputName: meronTextSource, text: meronName);
                  await _obs.setTextSource(inputName: meronWeight, text: "--");
                  await _obs.setTextSource(inputName: meronWB, text: "ULUTAN");

                  setState(() {
                    meronEntryName = meronName;
                  }); 
                  setState(() => _status = "$meronName manually set to Meron.");

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
                  await _obs.setTextSource(inputName: walaTextSource, text: walaName);
                  await _obs.setTextSource(inputName: walaWeight, text: "--");
                  await _obs.setTextSource(inputName: walaWB, text: "ULUTAN");

                  setState(() {
                    walaEntryName = walaName;
                  }); 
                  setState(() => _status = "$walaName manually set to Wala.");

                  await Future.delayed(preShowDelay);
                  await _obs.showEntryBanner(
                    fightSceneName: fightSceneName,
                    bannerSourceName: walaBanner,
                    duration: showDuration,
                  );
                  
                }
              }
            ),

            const Divider(),
            const SizedBox(height: 12),
            
            Row(
              children: [
                // Example: set OBS text + show banner using your existing ObsClient functions  
                FightInfo(numberOfFights: 6, entryName:  meronEntryName, backgroundColor: Colors.redAccent,),
                const SizedBox(width: 12),
                FightInfo(numberOfFights: 6, entryName:  walaEntryName, backgroundColor: Colors.blueAccent,),
                const SizedBox(width: 12),
                WinningSides(meronEntry: 'Meron Entry', walaEntry: 'Wala Entry', side: 'Meron', isChampion: false),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Scenes(),
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
            Text("Status: $_status", style: TextStyle(fontSize: 18),),
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
