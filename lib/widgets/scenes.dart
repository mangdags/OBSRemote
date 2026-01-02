import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Scenes extends StatefulWidget {
  const Scenes({super.key});

  @override
  State<Scenes> createState() => _ScenesState();
}

class _ScenesState extends State<Scenes> {
  final List<DropdownMenuItem<String>> obs_scenes = const [
    DropdownMenuItem(value: "2hits_right", child: Text("2 Hits Right")),
    DropdownMenuItem(value: "2hits_left", child: Text("2 Hits Left")),

    DropdownMenuItem(value: "3hits_right", child: Text("3 Hits Right")),
    DropdownMenuItem(value: "3hits_left", child: Text("3 Hits Left")),
    
    DropdownMenuItem(value: "4hits_right", child: Text("4 Hits Right")),
    DropdownMenuItem(value: "4hits_left", child: Text("4 Hits Left")),
    
    DropdownMenuItem(value: "5hits_right", child: Text("5 Hits Right")),
    DropdownMenuItem(value: "5hits_left", child: Text("5 Hits Left")),
  ];

  final List<DropdownMenuItem<String>> fight_hits = const [
    DropdownMenuItem(value: "1hit", child: Text("1 HIT")),
    DropdownMenuItem(value: "2hit", child: Text("2 HITS")),
    DropdownMenuItem(value: "3hit", child: Text("3 HITS")),
    DropdownMenuItem(value: "4hit", child: Text("4 HITS")),
    DropdownMenuItem(value: "5hit", child: Text("5 HITS")),
    DropdownMenuItem(value: "6hit", child: Text("6 HITS")),
    DropdownMenuItem(value: "7hit", child: Text("7 HITS")),
    DropdownMenuItem(value: "Ulutan", child: Text("ULUTAN")),
  ];

  String dropdownHitsValue = "1hit";

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 3,
      children: [
        const Expanded(flex: 1, child: Text('Fight: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),)),
        Expanded(
          flex: 2,
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'No.',
                  filled: true,
                  fillColor: Colors.yellow[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
        const SizedBox(width: 15),
        Expanded(
          flex: 9,
          child: Container(
            width:200, 
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton(isExpanded: true, items: obs_scenes, onChanged: (value) {}, hint: const Text('Select Default Scene'), 
            dropdownColor: Colors.yellow[50], padding: EdgeInsets.only(left: 10, right: 10 ),),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 9,
          child: Container(
            width:200, 
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton(
              value: dropdownHitsValue,
              isExpanded: true, 
              items: fight_hits, 
              onChanged: (String? newValue) {
                setState(() {
                  dropdownHitsValue = newValue!;
                });
              }, 
              hint: const Text('Select Hits'), 
              dropdownColor: Colors.yellow[50], padding: EdgeInsets.only(left: 10, right: 10 ),
            ),
          ),
        ),]
      );  }
}