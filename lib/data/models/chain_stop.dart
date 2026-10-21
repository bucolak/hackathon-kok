import 'heritage_site.dart';

class ChainStop {
  final String chainId;
  final int order;
  final HeritageSite site;
  final int unlockRadiusMeters;
  final String? story;
  final String? nextHint;

  const ChainStop({
    required this.chainId,
    required this.order,
    required this.site,
    required this.unlockRadiusMeters,
    this.story,
    this.nextHint,
  });

  factory ChainStop.fromMap(Map<String, dynamic> map) {
    return ChainStop(
      chainId: map['zincir_id'] as String,
      order: (map['sira'] as num).toInt(),
      site: HeritageSite.fromMap(map['eserler'] as Map<String, dynamic>),
      unlockRadiusMeters: (map['acilma_yaricapi_m'] as num?)?.toInt() ?? 60,
      story: map['hikaye'] as String?,
      nextHint: map['sonraki_ipucu'] as String?,
    );
  }
}