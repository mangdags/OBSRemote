import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FightInfo extends StatefulWidget {
  final int numberOfFights;
  final String entryName;
  final Color backgroundColor;

  /// NEW: pass the preset key so we can detect when a different fighter is selected
  final String presetKey;

  /// NEW: initial scores (1..n) from preset.scores
  final Map<int, String> scores;

  /// NEW: callback for saving (fightIndex is 1-based)
  final Future<void> Function(int fightIndex, String value)? onScoreChanged;

  const FightInfo({
    super.key,
    required this.numberOfFights,
    required this.entryName,
    required this.backgroundColor,
    required this.presetKey,
    required this.scores,
    this.onScoreChanged,
  }) : assert(numberOfFights >= 0);

  @override
  State<FightInfo> createState() => _FightInfoState();
}

class _FightInfoState extends State<FightInfo> {
  late List<TextEditingController> _ctrls;
  late List<String> _lastSynced; // to avoid re-saving same value
  bool _syncingFromParent = false;

  @override
  void initState() {
    super.initState();
    _buildControllersFromScores();
  }

  @override
  void didUpdateWidget(covariant FightInfo oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If fighter changed OR scores changed, push latest into textboxes
    final fighterChanged = oldWidget.presetKey != widget.presetKey;

    // Light “scores changed” check (safe + simple)
    bool scoresChanged = false;
    for (int i = 1; i <= widget.numberOfFights; i++) {
      final a = (oldWidget.scores[i] ?? "").trim();
      final b = (widget.scores[i] ?? "").trim();
      if (a != b) {
        scoresChanged = true;
        break;
      }
    }

    if (fighterChanged) {
      // rebuild controllers for new fighter
      _disposeControllers();
      _buildControllersFromScores();
      setState(() {});
      return;
    }

    if (scoresChanged) {
      _syncFromParentScores();
    }
  }

  void _buildControllersFromScores() {
    _ctrls = List.generate(widget.numberOfFights, (idx) {
      final fightIndex = idx + 1;
      final txt = (widget.scores[fightIndex] ?? "").toString();
      return TextEditingController(text: txt);
    });

    _lastSynced = List.generate(widget.numberOfFights, (idx) {
      final fightIndex = idx + 1;
      return (widget.scores[fightIndex] ?? "").trim();
    });
  }

  void _syncFromParentScores() {
    _syncingFromParent = true;
    try {
      for (int i = 1; i <= widget.numberOfFights; i++) {
        final newVal = (widget.scores[i] ?? "").toString();
        final c = _ctrls[i - 1];

        // update only if different (prevents cursor jumps)
        if (c.text != newVal) {
          c.text = newVal;
        }
        _lastSynced[i - 1] = newVal.trim();
      }
    } finally {
      _syncingFromParent = false;
    }
    setState(() {});
  }

  double _calcTotal() {
    double sum = 0;
    for (final c in _ctrls) {
      final t = c.text.trim();
      if (t.isEmpty) continue;
      final v = double.tryParse(t);
      if (v != null) sum += v;
    }
    return sum;
  }

  Future<void> _maybeSave(int fightIndex, String raw) async {
    if (_syncingFromParent) return;

    final v = raw.trim();

    // Allow only "", "0", "0.5", "1" (you can expand later)
    if (v.isNotEmpty && v != "0" && v != "0.5" && v != "1") {
      // revert to last known good value
      final prev = _lastSynced[fightIndex - 1];
      _ctrls[fightIndex - 1].text = prev;
      return;
    }

    // don't resave same value
    if (_lastSynced[fightIndex - 1] == v) return;

    _lastSynced[fightIndex - 1] = v;

    if (widget.onScoreChanged != null) {
      await widget.onScoreChanged!(fightIndex, v);
    }

    setState(() {});
  }

  void _disposeControllers() {
    for (final c in _ctrls) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcTotal();

    return Container(
      height: 250,
      width: 350,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.entryName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(color: Colors.white, thickness: 2),

          // Editable scores grid
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                children: List.generate(widget.numberOfFights, (idx) {
                  final fightIndex = idx + 1;
                  return SizedBox(
                    width: 55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        TextField(
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                          controller: _ctrls[idx],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^(|0|0\.5|1)$')),
                          ],
                          decoration: InputDecoration(
                            hintText: "F$fightIndex",
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                          onChanged: (v) => _maybeSave(fightIndex, v),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white, thickness: 2),
          Text(
            'Total Score: ${total.toStringAsFixed(total % 1 == 0 ? 0 : 1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
