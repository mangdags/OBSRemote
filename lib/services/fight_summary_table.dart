import 'package:flutter/material.dart';
import 'package:obsremote/models/fighter_preset.dart';
import 'package:obsremote/models/presets_repo.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class FightSummaryTable extends DataGridSource {
  final List<FighterPreset> fighters;
  final PresetsRepo presetsRepo;
  final int maxFights;

  FightSummaryTable({
    required this.fighters,
    required this.presetsRepo,
    this.maxFights = FighterPreset.maxFights,
  }) {
    buildDataGridRows();
  }

  List<DataGridRow> _dataGridRows = [];

  void buildDataGridRows() {
    _dataGridRows = fighters.map<DataGridRow>((fs) {
      final cells = <DataGridCell>[
        // Keep key so we know what to save
        DataGridCell<String>(columnName: 'key', value: fs.key),

        DataGridCell<String>(columnName: 'entryName', value: fs.entryName),

        for (int i = 1; i <= maxFights; i++)
          DataGridCell<String>(
            columnName: 'f$i',
            value: (fs.scores[i] ?? "").toString(),
          ),

        DataGridCell<double>(
          columnName: 'total',
          value: fs.scores.values.fold<double>(0.0, (prev, element) {
            final v = double.tryParse(element) ?? 0.0;
            return prev + v;
          }),
        ),

        // NOTES must be a String (not Widget) so it can be edited
        DataGridCell<String>(columnName: 'notes', value: fs.notes),
      ];

      return DataGridRow(cells: cells);
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  // --- EDITING STATE ---
  final TextEditingController _editCtrl = TextEditingController();

  @override
  Widget? buildEditWidget(
    DataGridRow row,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
    CellSubmit submitCell,
  ) {
    // We only allow editing NOTES (you can expand later)
    if (column.columnName != 'notes') return null;

    final displayText = row
            .getCells()
            .firstWhere((c) => c.columnName == 'notes')
            .value
            ?.toString() ??
        "";

    _editCtrl.text = displayText;

    return Container(
      padding: const EdgeInsets.all(6),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: _editCtrl,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        onSubmitted: (_) => submitCell(),
      ),
    );
  }

  @override
  Future<void> onCellSubmit(
    DataGridRow row,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
  ) async {
    if (column.columnName != 'notes') return;

    final presetKey = row
            .getCells()
            .firstWhere((c) => c.columnName == 'key')
            .value
            ?.toString() ??
        "";

    if (presetKey.isEmpty) return;

    final newNotes = _editCtrl.text;

    // Update the in-memory list so UI updates without reopening
    final idx = fighters.indexWhere((f) => f.key == presetKey);
    if (idx != -1) {
      fighters[idx] = fighters[idx].copyWith(notes: newNotes);
    }

    // Save to presets.json
    await presetsRepo.setNotes(
      presetKey: presetKey,
      notes: newNotes,
    );

    // Rebuild grid rows from updated data
    buildDataGridRows();
    notifyListeners();
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells:
          row.getCells().where((c) => c.columnName != 'key').map<Widget>((c) {
        final name = c.columnName;
        final val = c.value;

        Alignment align = Alignment.center;
        if (name == 'entryName' || name == 'notes')
          align = Alignment.centerLeft;

        return Container(
          alignment: align,
          padding: const EdgeInsets.all(8.0),
          child: Text(
            name == 'total'
                ? (val is double ? val.toStringAsFixed(1) : val.toString())
                : (val?.toString() ?? ""),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}
