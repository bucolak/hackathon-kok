class Chain {
  final String id;
  final String name;
  final String? theme;
  final String? description;
  final int distanceMeters;
  final int durationMinutes;
  final String? badgeId;

  const Chain({
    required this.id,
    required this.name,
    this.theme,
    this.description,
    required this.distanceMeters,
    required this.durationMinutes,
    this.badgeId,
  });

  factory Chain.fromMap(Map<String, dynamic> map) {
    return Chain(
      id: map['id'] as String,
      name: map['ad'] as String,
      theme: map['tema'] as String?,
      description: map['aciklama'] as String?,
      distanceMeters: (map['mesafe_m'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['sure_dk'] as num?)?.toInt() ?? 0,
      badgeId: map['rozet_id'] as String?,
    );
  }
}