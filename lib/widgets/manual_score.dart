import 'package:flutter/material.dart';

class ManualScore extends StatelessWidget {
  final List<double>? scores;

  const ManualScore({super.key, this.scores});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manual Score'),
          Row( 
            children: [
              for (var i = 0; i < (scores?.length ?? 5); i++)
                Container(
                  margin: const EdgeInsets.all(4.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    scores != null && i < scores!.length ? scores![i].toStringAsPrecision(1) : '-',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
          ],),
        ],
      ),
    );
  }
}