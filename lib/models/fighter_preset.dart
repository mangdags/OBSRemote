class FighterPreset {
  static const int maxFights = 12;

  final String key; // e.g. madam_kate
  final String entryName; // e.g. MADAM KATE
  final String w;
  final String wb;
  final Map<int, String> scores; // fightNumber -> score string
  final String notes;

  FighterPreset({
    required this.key,
    required this.entryName,
    this.w = "",
    this.wb = "",
    Map<int, String>? scores,
    this.notes = "",
  }) : scores = scores ?? {for (var i = 1; i <= maxFights; i++) i: ""};

  factory FighterPreset.fromJson(String key, Map<String, dynamic> json) {
    final scores = <int, String>{};
    for (var i = 1; i <= maxFights; i++) {
      scores[i] = (json["score_f$i"] ?? "").toString();
    }

    return FighterPreset(
      key: key,
      entryName: (json["entry_name"] ?? "").toString(),
      w: (json["w"] ?? "").toString(),
      wb: (json["wb"] ?? "").toString(),
      scores: scores,
      notes: (json["notes"] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      "entry_name": entryName,
      "w": w,
      "wb": wb,
      "notes": notes,
    };

    for (var i = 1; i <= maxFights; i++) {
      map["score_f$i"] = scores[i] ?? "";
    }

    return map;
  }

  FighterPreset copyWith({
    String? key,
    String? entryName,
    String? w,
    String? wb,
    Map<int, String>? scores,
    String? notes,
  }) {
    return FighterPreset(
      key: key ?? this.key,
      entryName: entryName ?? this.entryName,
      w: w ?? this.w,
      wb: wb ?? this.wb,
      scores: scores ?? Map<int, String>.from(this.scores),
      notes: notes ?? this.notes,
    );
  }

  String getScore(int i) {
    if (i < 1 || i > maxFights) return "";
    return scores[i] ?? "";
  }

  FighterPreset withScore(int fightNo, String value) {
    if (fightNo < 1 || fightNo > maxFights) return this;
    final next = Map<int, String>.from(scores);
    next[fightNo] = value;
    return copyWith(scores: next);
  }
}
