import 'package:flutter/material.dart';

class WinningSides extends StatelessWidget {
  /// NEW: logic hook (no UI changes)
  /// Expected values:
  /// "MeronWin", "WalaWin", "Draw", "Cancel", "MeronChamp", "WalaChamp"
  final Future<void> Function(String result)? onPickResult;

  const WinningSides({
    super.key,
    this.onPickResult,
  });

  Future<void> _fire(String result) async {
    if (onPickResult == null) return;
    await onPickResult!(result);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _fire("MeronWin"),
              style: ButtonStyle(
                backgroundColor:
                    const WidgetStatePropertyAll<Color>(Colors.redAccent),
                foregroundColor:
                    const WidgetStatePropertyAll<Color>(Colors.white),
                fixedSize: const WidgetStatePropertyAll<Size>(Size(130, 80)),
                shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text('MERON WINS'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _fire("WalaWin"),
              style: ButtonStyle(
                backgroundColor:
                    const WidgetStatePropertyAll<Color>(Colors.blueAccent),
                foregroundColor:
                    const WidgetStatePropertyAll<Color>(Colors.white),
                fixedSize: const WidgetStatePropertyAll<Size>(Size(130, 80)),
                shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text('WALA WINS'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _fire("Draw"),
              style: ButtonStyle(
                backgroundColor:
                    WidgetStatePropertyAll<Color>(Colors.yellowAccent[700]!),
                foregroundColor:
                    const WidgetStatePropertyAll<Color>(Colors.white),
                fixedSize: const WidgetStatePropertyAll<Size>(Size(130, 80)),
                shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text('DRAW FIGHT'),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _fire("MeronChamp"),
              style: ButtonStyle(
                backgroundColor:
                    WidgetStatePropertyAll<Color>(Colors.redAccent[700]!),
                foregroundColor:
                    const WidgetStatePropertyAll<Color>(Colors.white),
                fixedSize: const WidgetStatePropertyAll<Size>(Size(130, 80)),
                shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text('MERON CHAMP'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _fire("WalaChamp"),
              style: ButtonStyle(
                backgroundColor:
                    WidgetStatePropertyAll<Color>(Colors.blueAccent[700]!),
                foregroundColor:
                    const WidgetStatePropertyAll<Color>(Colors.white),
                fixedSize: const WidgetStatePropertyAll<Size>(Size(130, 80)),
                shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text('WALA CHAMP'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _fire("Cancel"),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(Colors.grey),
                foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
                fixedSize: WidgetStatePropertyAll<Size>(Size(130, 80)),
                shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text('CANCEL'),
            ),
          ],
        )
      ],
    );
  }
}
