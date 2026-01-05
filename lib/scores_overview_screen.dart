import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obsremote/models/fighter_preset.dart';
import 'package:obsremote/models/presets_repo.dart';
import 'package:obsremote/services/fight_summary_table.dart';
import 'package:obsremote/services/fights_storage.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ScoresOverviewScreen extends StatefulWidget {
  const ScoresOverviewScreen({super.key});

  @override
  State<ScoresOverviewScreen> createState() => _ScoresOverviewScreenState();
}

class _ScoresOverviewScreenState extends State<ScoresOverviewScreen> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  final _presetsRepo = PresetsRepo();

  List<FighterPreset> _fighters = [];
  List<FightRecord> _fights = [];

  bool _loading = true;
  String? _error;

  // optional: simple search
  final _searchCtrl = TextEditingController();

  // debounce writes (avoid spamming file I/O)
  final Map<String, Timer> _debounce = {};

  final maxF = FighterPreset.maxFights;
  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final t in _debounce.values) {
      t.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fighters = await _presetsRepo.loadPresets();
      final fights = await FightsStorage.loadAll();

      setState(() {
        _fighters = fighters;
        _fights = fights;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "$e";
        _loading = false;
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.redAccent : null,
      ),
    );
  }

  double _totalScore(FighterPreset f) {
    double sum = 0;
    for (final v in f.scores.values) {
      sum += double.tryParse(v) ?? 0.0;
    }
    return sum;
  }

  String _resultLabel(String r) {
    // keep this simple and display whatever you stored
    return r;
  }

  void _debouncedSave({
    required String key,
    required Duration delay,
    required Future<void> Function() action,
  }) {
    _debounce[key]?.cancel();
    _debounce[key] = Timer(delay, () async {
      try {
        await action();
      } catch (e) {
        _snack("Save failed: $e", error: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final fightersFiltered = q.isEmpty
        ? _fighters
        : _fighters.where((f) {
            return f.entryName.toLowerCase().contains(q) ||
                f.key.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fighters Overview"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Failed to load:\n$_error",
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Search bar (optional, doesn’t touch your existing UI)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          hintText: "Search entry name / key...",
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 3,
                      child: SfDataGrid(
                        gridLinesVisibility: GridLinesVisibility.both,
                        headerGridLinesVisibility: GridLinesVisibility.both,
                        frozenColumnsCount: 1,
                        rowHeight: 60,
                        allowColumnsResizing: true,
                        allowSorting: true,
                        source: FightSummaryTable(fights: _fighters), columns: [
                        
                        GridColumn(
                          
                          columnWidthMode: ColumnWidthMode.fill,
                          columnName: 'entryName',
                          minimumWidth: 200,
                          maximumWidth: 250,
                          allowSorting: false,
                          label: Container(
                              padding: const EdgeInsets.all(8.0),
                              alignment: Alignment.centerLeft,
                              child: const Text('ENTRY NAME'),
                              )
                            ),
                        for (int i = 1; i <= maxF; i++)
                          GridColumn(
                        allowSorting: false,
                            width: 40,
                              columnName: 'f$i',
                              label: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text('F$i'))),
                        GridColumn(
                            columnName: 'total',
                            allowSorting: true,
                            width: 85,
                            label: Container(
                                padding: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: const Text('TOTAL'))),
                        GridColumn(
                            columnName: 'notes',
                            allowEditing: true,
                        allowSorting: false,
                            width: 130,
                            label: Container(
                                padding: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: const Text('NOTES'))),
                      ]),
                    ),
                    const Divider(thickness: 2),
                    Expanded(
                      flex: 2,
                      child: _fightsTable(),
                    ),
                  ],
                ),
    );
  }

  

  DataRow _fighterRow(FighterPreset f) {
    final maxF = FighterPreset.maxFights;
    final total = _totalScore(f);

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
              width: 260,
              child: Text(f.entryName, overflow: TextOverflow.ellipsis)),
        ),
        for (int i = 1; i <= maxF; i++) _scoreCell(f, i),
        DataCell(SizedBox(
            width: 60,
            child: Text(
              total.toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), ""),
              textAlign: TextAlign.center,
            ))),
        DataCell(_notesEditorCell(f)),
      ],
    );
  }

  DataCell _scoreCell(FighterPreset f, int fightIdx) {
    final val = f.scores[fightIdx] ?? "";

    return DataCell(
      InkWell(
        onTap: () async {
          final next = await _editScoreDialog(
            title: "${f.entryName} - F$fightIdx",
            initial: val,
          );
          if (next == null) return; // cancelled

          // update local UI immediately
          final nextScores = Map<int, String>.from(f.scores);
          nextScores[fightIdx] = next;

          final idx = _fighters.indexWhere((x) => x.key == f.key);
          if (idx != -1) {
            setState(() {
              _fighters[idx] = f.copyWith(scores: nextScores);
            });
          }

          // save to presets.json
          _debouncedSave(
            key: "save_${f.key}_$fightIdx",
            delay: const Duration(milliseconds: 250),
            action: () => _presetsRepo.setScore(
              presetKey: f.key,
              fightNo: fightIdx,
              value: next,
            ),
          );
        },
        child: SizedBox(
          width: 48,
          child: Center(
            child: Text(
              val,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _editScoreDialog({
    required String title,
    required String initial,
  }) async {
    final ctrl = TextEditingController(text: initial);

    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "0 / 0.5 / 1",
          ),
          onSubmitted: (_) => Navigator.pop(context, ctrl.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    final v = res?.trim();
    if (v == null) return null;

    // optional validation:
    // allow "", "0", "0.5", "1"
    if (v.isNotEmpty && v != "0" && v != "0.5" && v != "1") {
      _snack("Allowed values: 0, 0.5, 1 (or blank)", error: true);
      return null;
    }

    return v;
  }

  Widget _notesEditorCell(FighterPreset f) {
    final initial = f.notes;
    final k = ValueKey("notes_${f.key}");

    return SizedBox(
      width: 220,
      child: TextFormField(
        key: k,
        initialValue: initial,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: OutlineInputBorder(),
        ),
        onChanged: (v) {
          // just debounce write; we don’t need live UI updates for notes
          _debouncedSave(
            key: "notes_${f.key}",
            delay: const Duration(milliseconds: 600),
            action: () => _presetsRepo.setNotes(
              presetKey: f.key,
              notes: v,
            ),
          );
        },
      ),
    );
  }

  Widget _fightsTable() {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text("Fight #")),
              DataColumn(label: Text("Meron Entry")),
              DataColumn(label: Text("Wala Entry")),
              DataColumn(label: Text("Winning Side")),
            ],
            rows: _fights.map((f) {
              return DataRow(
                cells: [
                  DataCell(Text("${f.fightNumber}")),
                  DataCell(SizedBox(width: 260, child: Text(f.meronEntry))),
                  DataCell(SizedBox(width: 260, child: Text(f.walaEntry))),
                  DataCell(Text(_resultLabel(f.result))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
