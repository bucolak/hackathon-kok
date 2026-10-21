class HeritageSite {
  const HeritageSite({
    required this.id,
    required this.district,
    required this.name,
    required this.displayName,
    required this.type,
    required this.source,
    required this.latitude,
    required this.longitude,
    this.summary,
    this.history,
  });

  final String id;
  final String district;
  final String name;
  final String displayName;
  final String type;
  final String source;
  final double latitude;
  final double longitude;
  final String? summary;
  final String? history;

  factory HeritageSite.fromMap(Map<String, dynamic> map) {
    return HeritageSite(
      id: map['id'] as String,
      district: map['ilce'] as String,
      name: map['ad'] as String,
      displayName: map['guncel_ad'] as String,
      type: map['eser_turu'] as String,
      source: map['kaynak'] as String,
      latitude: (map['enlem'] as num).toDouble(),
      longitude: (map['boylam'] as num).toDouble(),
      summary: map['ozet'] as String?,
      history: map['tarihce'] as String?,
    );
  }
}