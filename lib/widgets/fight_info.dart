import 'package:flutter/material.dart';

class FightInfo extends StatelessWidget {
  final int numberOfFights;
  final String entryName;
  final Color backgroundColor;

  /// Optional: if you want to show custom labels instead of just F1..Fn
  /// Example: fightLabels: ["F1", "F2", ...] or ["1", "2", ...]
  final List<String>? fightLabels;

  const FightInfo({
    super.key,
    required this.numberOfFights,
    this.entryName = "",
    this.fightLabels,
    this.backgroundColor = Colors.grey,
  }) : assert(numberOfFights >= 0);

  @override
  Widget build(BuildContext context) {
    final labels =
        fightLabels ?? List.generate(numberOfFights, (i) => 'F${i + 1}: ');

    return Container(
      height: 250,
      width: 350,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entryName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(color: Colors.white, thickness: 2),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: labels.map((t) => _FightTag(text: t)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Total: ',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              )),
          const Divider(color: Colors.white, thickness: 2),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(
                    Colors.white,
                  ),
                ),
                child: Text(
                  'Update Score',
                  style: TextStyle(color: Colors.black),
                )),
          ),
        ],
      ),
    );
  }
}

class _FightTag extends StatelessWidget {
  final String text;
  const _FightTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
