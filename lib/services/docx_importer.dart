import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class FighterPreset {
  final String key;
  final String entryName;
  final String w;
  final String wb;

  FighterPreset({
    required this.key,
    required this.entryName,
    required this.w,
    required this.wb,
  });

  Map<String, dynamic> toJson() => {
        "entry_name": entryName,
        "w": w,
        "wb": wb,
        "score_f1": "",
        "score_f2": "",
        "score_f3": "",
        "score_f4": "",
        "score_f5": "",
        "score_f6": "",
        "score_f7": "",
        "notes": "",
      };
}

class DocxImporterResult {
  final Map<String, FighterPreset> presets;
  final bool looksLikeNewFormat;

  DocxImporterResult(this.presets, this.looksLikeNewFormat);
}

class DocxImporter {
  /// Extracts fighter presets from the FIRST table in the DOCX,
  /// supporting your two formats:
  /// NEW: [FT][ENTRY][LB][WB][WT] | [ENTRY][LB][WB][WT]
  /// OLD: [#][LeftName][LeftW][LeftWB][VS][RightName][RightW][RightWB]
  static DocxImporterResult importFromBytes(Uint8List bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);

  // Try document.xml first (most cases)
  final primary = zip.files.where((f) => f.name == 'word/document.xml').toList();

  // If not found (rare), scan other word/*.xml as fallback
  final fallback = zip.files.where((f) =>
      f.name.startsWith('word/') &&
      f.name.endsWith('.xml') &&
      f.isFile).toList();

  final candidates = [...primary, ...fallback];

  if (candidates.isEmpty) {
    throw StateError('Invalid DOCX: no word/*.xml found.');
  }

  XmlDocument? doc;
  String? usedFile;

  // Parse the first XML that actually contains a table
  for (final f in candidates) {
    try {
      final xmlString = utf8.decode(f.content as List<int>);
      final d = XmlDocument.parse(xmlString);
      final hasTbl = d.descendantElements.any((e) => e.name.local == 'tbl');
      if (hasTbl) {
        doc = d;
        usedFile = f.name;
        break;
      }
    } catch (_) {
      // ignore parse failures, keep trying
    }
  }

  if (doc == null) {
    throw StateError('No tables found in DOCX (scanned: ${candidates.map((e) => e.name).join(", ")}).');
  }

  // Find all tables (by localName, namespace-safe)
  final tables = doc.descendantElements.where((e) => e.name.local == 'tbl').toList();
  if (tables.isEmpty) {
    throw StateError('No tables found in DOCX ($usedFile).');
  }

  final firstTable = tables.first;

  // --- helpers ---
  List<XmlElement> rowCells(XmlElement row) =>
      row.descendantElements.where((e) => e.name.local == 'tc').toList();

  String cellText(XmlElement cell) {
    final texts = cell.descendantElements
        .where((e) => e.name.local == 't')
        .map((e) => e.innerText)
        .toList();
    return texts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String entryNameFirstLine(XmlElement cell) {
    // first paragraph only (closest match to your WPF)
    final p = cell.descendantElements.firstWhere(
      (e) => e.name.local == 'p',
      orElse: () => cell,
    );

    final texts = p.descendantElements
        .where((e) => e.name.local == 't')
        .map((e) => e.innerText)
        .toList();

    final s = texts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.isNotEmpty ? s : cellText(cell);
  }

  // rows (w:tr)
  final rows = firstTable.descendantElements.where((e) => e.name.local == 'tr').toList();
  if (rows.isEmpty) throw StateError('DOCX table has no rows.');

  // Header detection based on YOUR headers
  final headerCells = rowCells(rows[0]);
  String headerAt(int i) => (i < headerCells.length) ? cellText(headerCells[i]).toUpperCase() : "";

  // Your format header example:
  // [0 blank/#] [1 NAME OF ENTRY] [2 W] [3 WB#] [4 VS] [5 NAME OF ENTRY] [6 W] [7 WB#]
  final looksLikeOldFormat =
      headerCells.length >= 8 &&
      headerAt(1).contains("NAME") &&
      headerAt(2) == "W" &&
      headerAt(3).contains("WB") &&
      headerAt(4).contains("VS");

  // New format (your older WPF “WT” layout) is NOT what you showed,
  // but keep detection anyway if you still use it elsewhere.
  final looksLikeNewFormat =
      headerCells.length >= 9 &&
      headerAt(1).contains("ENTRY") &&
      headerAt(3).contains("WB") &&
      headerAt(4).contains("WT");

  final imported = <String, FighterPreset>{};

  for (int r = 1; r < rows.length; r++) {
    final cells = rowCells(rows[r]);
    if (cells.isEmpty) continue;

    String? leftName, leftW, leftWB;
    String? rightName, rightW, rightWB;

    if (looksLikeNewFormat) {
      // NEW FORMAT (kept)
      if (cells.length >= 5) {
        leftName = entryNameFirstLine(cells[1]);
        leftWB = (cells.length > 3) ? cellText(cells[3]) : "";
        leftW  = (cells.length > 4) ? cellText(cells[4]) : "";
      }
      if (cells.length >= 9) {
        rightName = entryNameFirstLine(cells[5]);
        rightWB = cellText(cells[7]);
        rightW  = cellText(cells[8]);
      }
    } else if (looksLikeOldFormat) {
      // OLD FORMAT (your screenshot)
      // [1 LeftName] [2 LeftW] [3 LeftWB] [5 RightName] [6 RightW] [7 RightWB]
      if (cells.length > 3) {
        leftName = entryNameFirstLine(cells[1]);
        leftW  = cellText(cells[2]);
        leftWB = cellText(cells[3]);
      }
      if (cells.length > 7) {
        rightName = entryNameFirstLine(cells[5]);
        rightW  = cellText(cells[6]);
        rightWB = cellText(cells[7]);
      }
    } else {
      // If header detection fails, still try best-effort old layout
      if (cells.length > 3) {
        leftName = entryNameFirstLine(cells[1]);
        leftW  = cellText(cells[2]);
        leftWB = cellText(cells[3]);
      }
      if (cells.length > 7) {
        rightName = entryNameFirstLine(cells[5]);
        rightW  = cellText(cells[6]);
        rightWB = cellText(cells[7]);
      }
    }

    void addFighter(String? name, String? w, String? wb) {
      final n = (name ?? "").trim();
      if (n.isEmpty) return;

      final key = generateKeyFromName(n);

      imported[key] = FighterPreset(
        key: key,
        entryName: n,
        w: (w ?? "").trim(),
        wb: (wb ?? "").trim(),
      );
    }

    addFighter(leftName, leftW, leftWB);
    addFighter(rightName, rightW, rightWB);
  }

  return DocxImporterResult(imported, looksLikeNewFormat);
}


  static String generateKeyFromName(String name) {
    final lower = name.toLowerCase().trim();
    final sb = StringBuffer();
    for (final code in lower.runes) {
      final ch = String.fromCharCode(code);
      if (RegExp(r'[a-z0-9]').hasMatch(ch)) {
        sb.write(ch);
      } else {
        sb.write('_');
      }
    }
    var key = sb.toString();
    while (key.contains('__')) key = key.replaceAll('__', '_');
    key = key.replaceAll(RegExp(r'^_+|_+$'), '');
    return key.isEmpty ? 'fighter' : key;
  }
}
