import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obsremote/models/fighter_preset.dart';
import 'package:obsremote/obs_client.dart';

class Scenes extends StatefulWidget {
  final ObsClient obs;

  /// Send selected default scene key/name back to Home
  final ValueChanged<String?>? onDefaultSceneChanged;

  /// Send fight number back to Home (int)
  final ValueChanged<int>? onFightNumberChanged;

  const Scenes({
    super.key,
    required this.obs,
    this.onDefaultSceneChanged,
    this.onFightNumberChanged,
  });

  @override
  State<Scenes> createState() => ScenesState();
}

class ScenesState extends State<Scenes> {
  final List<DropdownMenuItem<String>> obsScenes = const [
    DropdownMenuItem(value: "2 HITS RIGHT CAM", child: Text("2 Hits Right")),
    DropdownMenuItem(value: "2 HITS LEFT CAM", child: Text("2 Hits Left")),
    DropdownMenuItem(value: "3 HITS RIGHT CAM", child: Text("3 Hits Right")),
    DropdownMenuItem(value: "3 HITS LEFT CAM", child: Text("3 Hits Left")),
    DropdownMenuItem(value: "4 HITS RIGHT CAM", child: Text("4 Hits Right")),
    DropdownMenuItem(value: "4 HITS LEFT CAM", child: Text("4 Hits Left")),
    DropdownMenuItem(value: "5 HITS RIGHT CAM", child: Text("5 Hits Right")),
    DropdownMenuItem(value: "5 HITS LEFT CAM", child: Text("5 Hits Left")),
  ];

  final List<DropdownMenuItem<String>> fightHits = const [
    DropdownMenuItem(value: "1hit", child: Text("1 HIT")),
    DropdownMenuItem(value: "2hit", child: Text("2 HITS")),
    DropdownMenuItem(value: "3hit", child: Text("3 HITS")),
    DropdownMenuItem(value: "4hit", child: Text("4 HITS")),
    DropdownMenuItem(value: "5hit", child: Text("5 HITS")),
    DropdownMenuItem(value: "6hit", child: Text("6 HITS")),
    DropdownMenuItem(value: "7hit", child: Text("7 HITS")),
    DropdownMenuItem(value: "Ulutan", child: Text("ULUTAN")),
  ];

  final String fightNumberSource = "FightNumber";
  Timer? _fightNoDebounce;

  String? dropdownHitsValue;
  String? dropdownScenesValue;

  final TextEditingController _fightNoCtrl = TextEditingController();

  Future<void> setFightNumber(int n) async {
    final v = n.toString();

    // ✅ updates the TextField visually
    _fightNoCtrl.text = v;

    // keep cursor at the end
    _fightNoCtrl.selection = TextSelection.collapsed(offset: v.length);

    // notify Home state if needed
    widget.onFightNumberChanged?.call(n);

    // update OBS text
    if (!widget.obs.isConnected) return;
    try {
      await widget.obs.setTextSource(
        inputName: fightNumberSource,
        text: v,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _fightNoDebounce?.cancel();
    _fightNoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(spacing: 3, children: [
      const Expanded(
        flex: 1,
        child: Text(
          'Fight: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // Fight number input (same UI)
      Expanded(
        flex: 2,
        child: TextField(
          controller: _fightNoCtrl, // ✅ REQUIRED
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: 'No.',
            filled: true,
            fillColor: Colors.yellow[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          onChanged: (v) {
            final n = int.tryParse(v) ?? 0;
            if (n > 0) widget.onFightNumberChanged?.call(n);

            _fightNoDebounce?.cancel();
            _fightNoDebounce =
                Timer(const Duration(milliseconds: 250), () async {
              if (!widget.obs.isConnected) return;
              try {
                await widget.obs.setTextSource(
                  inputName: fightNumberSource,
                  text: v,
                );
              } catch (_) {}
            });
          },
        ),
      ),

      const SizedBox(width: 15),

      // Default scene dropdown (same UI)
      Expanded(
        flex: 9,
        child: Container(
          width: 200,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonFormField<String>(
            value: dropdownScenesValue,
            items: obsScenes,
            onChanged: (v) {
              setState(() => dropdownScenesValue = v);
              widget.onDefaultSceneChanged?.call(v);
            },
            decoration: InputDecoration(
              hintText: 'Select Default Scene',
              filled: true,
              fillColor: Colors.yellow[50],
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ),

      const SizedBox(width: 15),

      // Hits dropdown (unchanged UI; kept as-is)
      Expanded(
        flex: 9,
        child: Container(
          width: 200,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonFormField<String>(
            value: dropdownHitsValue,
            items: fightHits,
            onChanged: (v) => setState(() => dropdownHitsValue = v),
            decoration: InputDecoration(
              hintText: 'Select Default Hits',
              filled: true,
              fillColor: Colors.yellow[50],
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ),
    ]);
  }
}
