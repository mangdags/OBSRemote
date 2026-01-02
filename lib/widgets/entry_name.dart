import 'package:flutter/material.dart';
import '../models/presets_repo.dart';
import '../models/fighter_preset.dart';

class EntryName extends StatefulWidget {
  final String title;

  /// Called when user clicks SET AS MERON / WALA from dropdown selection.
  final Future<void> Function(FighterPreset preset)? onSetMeron;
  final Future<void> Function(FighterPreset preset)? onSetWala;

  /// Called when user clicks USE MANUAL NAMES.
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
  State<EntryName> createState() => _EntryNameState();
}

class _EntryNameState extends State<EntryName> {
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final presets = await _repo.loadPresets();
      setState(() {
        _all = presets;
        _filtered = presets;
        _selected = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load presets.json: $e";
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();

    final next = q.isEmpty
        ? _all
        : _all.where((p) {
            return p.entryName.toLowerCase().contains(q) ||
                p.key.toLowerCase().contains(q);
          }).toList();

    setState(() {
      _filtered = next;
      // If selection is no longer in filtered list, clear it
      if (_selected != null && !_filtered.any((x) => x.key == _selected!.key)) {
        _selected = null;
      }
    });
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
    if (_loading) {
      return _card(child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text("Loading presets.json ..."),
        ]),
      ));
    }

    if (_error != null) {
      return _card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(width: 10),
              TextButton(onPressed: _load, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    onChanged: (v) => setState(() => _selected = v),
                    decoration: InputDecoration(
                      hintText: "Select Entry Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      : () => widget.onSetMeron!(_selected!),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.disabled) ? Colors.redAccent.withOpacity(.35) : Colors.redAccent,
                    ),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  child: const Text("SET AS MERON", style: TextStyle(color: Colors.white)),
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
                      : () => widget.onSetWala!(_selected!),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.disabled) ? Colors.blueAccent.withOpacity(.35) : Colors.blueAccent,
                    ),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  child: const Text("SET AS WALA", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Manual names section
          Text("Manual Meron/Wala", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
              Expanded(
                flex: 1,
                child: TextButton(
                    onPressed: widget.onUseManualMeron == null
                        ? null
                        : () => widget.onUseManualMeron!(
                              _manualMeronCtrl.text.trim(),
                            ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.blueGrey),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    child: const Text("GO", style: TextStyle(color: Colors.white)),
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
              Expanded(
                flex: 1,
                child: TextButton(
                  onPressed: widget.onUseManualWala == null
                      ? null
                      : () => widget.onUseManualWala!(
                            _manualWalaCtrl.text.trim(),
                          ),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.blueGrey),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  child: const Text("GO", style: TextStyle(color: Colors.white)),
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
