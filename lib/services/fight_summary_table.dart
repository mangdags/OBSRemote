import 'package:flutter/material.dart';
import 'package:obsremote/models/fighter_preset.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class FightSummaryTable extends DataGridSource{
  List<FighterPreset> fights;

  FightSummaryTable({required this.fights}) {
    buildDataGridRows();
  }

  List<DataGridRow> _dataGridRows = [];

  void buildDataGridRows() {
    _dataGridRows = fights
        .map<DataGridRow>((fs) => DataGridRow(cells: [
                DataGridCell<String>(columnName: 'entryName', value: fs.entryName),
                DataGridCell<String>(columnName: 'f1', value: fs.scores[1]),
                DataGridCell<String>(columnName: 'f2', value: fs.scores[2]),
                DataGridCell<String>(columnName: 'f3', value: fs.scores[3]),
                DataGridCell<String>(columnName: 'f4', value: fs.scores[4]),
                DataGridCell<String>(columnName: 'f5', value: fs.scores[5]),
                DataGridCell<String>(columnName: 'f6', value: fs.scores[6]),
                DataGridCell<String>(columnName: 'f7', value: fs.scores[7]),
                DataGridCell<String>(columnName: 'f8', value: fs.scores[8]),
                DataGridCell<String>(columnName: 'f9', value: fs.scores[9]),
                DataGridCell<String>(columnName: 'f10', value: fs.scores[10]),
                DataGridCell<String>(columnName: 'f11', value: fs.scores[11]),
                DataGridCell<String>(columnName: 'f12', value: fs.scores[12]),
                DataGridCell<int>(columnName: 'total', value: fs.scores.values.fold<int>(0, (prev, element) {
                  final v = int.tryParse(element) ?? 0;
                  return prev + v;
                })),
                DataGridCell<Widget>(columnName: 'notes', value: Text(fs.notes)),
              ]))
        .toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(cells: row.getCells().map<Widget>((dataCell) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: Text(dataCell.value.toString()),
      );
    }).toList());
  }
}