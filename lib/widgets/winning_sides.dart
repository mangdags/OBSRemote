import 'package:flutter/material.dart';

class WinningSides extends StatelessWidget {
  final String meronEntry;
  final String walaEntry;
  final String side;
  final bool isChampion;

  const WinningSides({super.key, required this.meronEntry, required this.walaEntry, required this.side, required this.isChampion});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: (){}, 
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
              foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
              fixedSize: WidgetStatePropertyAll<Size>(const Size(130, 80)),
              shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ), child: Text('MERON WINS'),),
            const SizedBox(height: 12),
            TextButton(onPressed: (){}, 
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.blueAccent),
                  foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
                  fixedSize: WidgetStatePropertyAll<Size>(const Size(130, 80)),
                  shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ), child: Text('WALA WINS'),),
            const SizedBox(height: 12),
            TextButton(onPressed: (){}, 
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.yellowAccent[700]!),
                  foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
                  fixedSize: WidgetStatePropertyAll<Size>(const Size(130, 80)),
                  shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ), child: Text('DRAW FIGHT'),),
            ],),
        const SizedBox(width: 20),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            TextButton(onPressed: (){}, 
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Colors.redAccent[700]!),
              foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
              fixedSize: WidgetStatePropertyAll<Size>(const Size(130, 80)),
              shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ), child: Text('MERON CHAMP'),),
            const SizedBox(height: 12),
            TextButton(onPressed: (){}, 
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Colors.blueAccent[700]!),
              foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
              fixedSize: WidgetStatePropertyAll<Size>(const Size(130, 80)),
              shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ), child: Text('WALA CHAMP'),),
            const SizedBox(height: 12),
            TextButton(onPressed: (){}, 
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Colors.grey),
              foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
              fixedSize: WidgetStatePropertyAll<Size>(const Size(130, 80)),
              shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ), child: Text('CANCEL'),),
          ],
        )
      ],
        
    );
  }
}