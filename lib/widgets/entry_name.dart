import 'package:flutter/material.dart';
import '../models/presets_repo.dart';
import '../models/fighter_preset.dart';

class EntryName extends StatefulWidget {
  final String title;

  /// Called when user clicks SET AS MERON / WALA from dropdown selection.
  final Future<void> Function(FighterPreset preset)? onSetMeron;
  final Future<void> Function(FighterPreset preset)? onSetWala;

  /// Called after manual name is saved/created in presets.json
  final Future<void> Function(String meronName)? onUseManualMeron;
  final Future<void> Function(String walaName)? onUseManualWala;

  const EntryName({
    super.key,
    required this.title,
    this.onSetMeron,
    this.onSetWala,
    this.onUseManualMeron,
    this.onUseManualWala,
  });

  @override
  State<EntryName> createState() => EntryNameState();
}

class EntryNameState extends State<EntryName> {
  final _repo = PresetsRepo();

  final _searchCtrl = TextEditingController();
  final _manualMeronCtrl = TextEditingController();
  final _manualWalaCtrl = TextEditingController();

  List<FighterPreset> _all = [];
  List<FighterPreset> _filtered = [];
  FighterPreset? _selected;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  Future<void> refresh() async {
    _searchCtrl.clear();
    _manualMeronCtrl.clear();
    _manualWalaCtrl.clear();

    setState(() {
      _selected = null;
    });

    await _load(); // will rebuild _all/_filtered safely
  }

  void clearInputsOnly() {
    _searchCtrl.clear();
    _manualMeronCtrl.clear();
    _manualWalaCtrl.clear();
    setState(() {
      _selected = null;
      _filtered = _all;
    });
  }

  void _snack(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final presets = await _repo.loadPresets();

      // rebind selection to the *new* instance in the loaded list
      final prevKey = _selected?.key;
      FighterPreset? rebound;
      if (prevKey != null) {
        try {
          rebound = presets.firstWhere((p) => p.key == prevKey);
        } catch (_) {
          rebound = null;
        }
      }

      setState(() {
        _all = presets;

        // apply filter using current search text
        final q = _searchCtrl.text.trim().toLowerCase();
        _filtered = q.isEmpty
            ? _all
            : _all
                .where((p) =>
                    p.entryName.toLowerCase().contains(q) ||
                    p.key.toLowerCase().contains(q))
                .toList();

        _filtered = {
          for (final p in _filtered) p.key: p,
        }.values.toList();

        // selection must be an element of _filtered (and be that exact instance)
        if (rebound != null && _filtered.any((x) => x.key == rebound!.key)) {
          _selected = _filtered.firstWhere((x) => x.key == rebound!.key);
        } else {
          _selected = null;
        }

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _all = [];
        _filtered = [];
        _selected = null;
        _error = "Failed to load presets.json: $e";
        _loading = false;
      });
    }
  }

  List<FighterPreset> _filterList(List<FighterPreset> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;

    return source.where((p) {
      return p.entryName.toLowerCase().contains(q) ||
          p.key.toLowerCase().contains(q);
    }).toList();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();

    final next = q.isEmpty
        ? _all
        : _all.where((p) {
            return p.entryName.toLowerCase().contains(q) ||
                p.key.toLowerCase().contains(q);
          }).toList();

    final deduped = {
      for (final p in next) p.key: p,
    }.values.toList();

    setState(() {
      _filtered = deduped;

      if (_selected != null && !_filtered.any((x) => x.key == _selected!.key)) {
        _selected = null;
      }
    });
  }

  Future<void> _useManualMeron() async {
    final name = _manualMeronCtrl.text.trim();
    if (name.isEmpty) {
      _snack("Meron name is empty.", isError: true);
      return;
    }

    try {
      final preset = await _repo.upsertFromEntryName(name);
      await _load(); // refresh dropdown
      await widget.onUseManualMeron?.call(name);

      _snack(
          'Saved "${preset.entryName}" to presets.json (key: ${preset.key})');
    } catch (e) {
      setState(() => _error = "Failed saving manual Meron: $e");
      _snack("Failed saving Meron: $e", isError: true);
    }
  }

  Future<void> _useManualWala() async {
    final name = _manualWalaCtrl.text.trim();
    if (name.isEmpty) {
      _snack("Wala name is empty.", isError: true);
      return;
    }

    try {
      final preset = await _repo.upsertFromEntryName(name);
      await _load(); // refresh dropdown
      await widget.onUseManualWala?.call(name);

      _snack(
          'Saved "${preset.entryName}" to presets.json (key: ${preset.key})');
    } catch (e) {
      setState(() => _error = "Failed saving manual Wala: $e");
      _snack("Failed saving Wala: $e", isError: true);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _manualMeronCtrl.dispose();
    _manualWalaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Loading indicator (non-blocking)
          if (_loading) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text("Loading presets.json ..."),
                ],
              ),
            ),
          ],

          // Error banner (THIS TIME it is included in the tree)
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text("Retry")),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Search + dropdown + buttons row
          Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search entry name / key...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Dropdown
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 50,
                  child: DropdownButtonFormField<FighterPreset>(
                    value: _selected,
                    isExpanded: true,
                    items: _filtered
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.entryName),
                            ))
                        .toList(),
                    onChanged: _filtered.isEmpty
                        ? null
                        : (v) => setState(() => _selected = v),
                    decoration: InputDecoration(
                      hintText: _filtered.isEmpty
                          ? "No presets loaded"
                          : "Select Entry Name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Set as Meron
              SizedBox(
                height: 50,
                width: 160,
                child: TextButton(
                  onPressed: (_selected == null || widget.onSetMeron == null)
                      ? null
                      : () async {
                          try {
                            _snack('Set MERON: "${_selected!.entryName}"');
                            await widget.onSetMeron!(_selected!);
                          } catch (e) {
                            _snack("Failed to set MERON: $e", isError: true);
                          }
                        },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.disabled)
                          ? Colors.redAccent.withOpacity(.35)
                          : Colors.redAccent,
                    ),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                  ),
                  child: const Text("SET AS MERON",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),

              // Set as Wala
              SizedBox(
                height: 50,
                width: 160,
                child: TextButton(
                  onPressed: (_selected == null || widget.onSetWala == null)
                      ? null
                      : () async {
                          try {
                            _snack('Set WALA: "${_selected!.entryName}"');
                            await widget.onSetWala!(_selected!);
                          } catch (e) {
                            _snack("Failed to set WALA: $e", isError: true);
                          }
                        },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.disabled)
                          ? Colors.blueAccent.withOpacity(.35)
                          : Colors.blueAccent,
                    ),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                  ),
                  child: const Text("SET AS WALA",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Manual names section
          const Text("Manual Meron/Wala",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                flex: 8,
                child: TextField(
                  controller: _manualMeronCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Meron Entry Name",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                width: 70,
                child: TextButton(
                  onPressed: _useManualMeron,
                  style: ButtonStyle(
                    backgroundColor:
                        const WidgetStatePropertyAll(Colors.blueGrey),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                  ),
                  child:
                      const Text("GO", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 8,
                child: TextField(
                  controller: _manualWalaCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Wala Entry Name",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                width: 70,
                child: TextButton(
                  onPressed: _useManualWala,
                  style: ButtonStyle(
                    backgroundColor:
                        const WidgetStatePropertyAll(Colors.blueGrey),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                  ),
                  child:
                      const Text("GO", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
