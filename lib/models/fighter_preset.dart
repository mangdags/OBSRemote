class FighterPreset {
  final String key;
  final String entryName;
  final String w;
  final String wb;
  final String notes;

  const FighterPreset({
    required this.key,
    required this.entryName,
    this.w = "",
    this.wb = "",
    this.notes = "",
  });

  factory FighterPreset.fromJson(String key, Map<String, dynamic> json) {
    return FighterPreset(
      key: key,
      entryName: (json["entry_name"] ?? key).toString(),
      w: (json["w"] ?? "").toString(),
      wb: (json["wb"] ?? "").toString(),
      notes: (json["notes"] ?? "").toString(),
    );
  }
}
