import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/discovery_location.dart';

/// Harita girdisi; Supabase modeline bağımlı değildir.
class HeritageMapSite {
  const HeritageMapSite({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final double? latitude;
  final double? longitude;

  /// Web Mercator sınırları dahil haritada gösterilebilir koordinat kontrolü.
  bool get hasValidCoordinates =>
      DiscoveryLocation(
        id: id,
        latitude: latitude,
        longitude: longitude,
      ).hasValidCoordinates &&
      latitude!.abs() <= 85.05112878;
}

/// Sınırlı genişlik/yükseklik sağlayan bir üst widget içinde kullanılmalıdır.
/// GPS izni istemez, veri indirmez ve ziyaret doğrulamaz. Yalnızca görünür
/// harita karolarını yükler; rota, ön indirme veya çevrimdışı indirme içermez.
class HeritageMap extends StatelessWidget {
  const HeritageMap({
    super.key,
    required this.sites,
    required this.onSiteTap,
    this.userLocation,
    this.tileProvider,
    this.interactive = true,
    this.onTileError,
  });

  /// Sayfa içi önizlemede kapatılır; atıf ve işaretçi düğmeleri çalışır.
  final bool interactive;

  final VoidCallback? onTileError;

  final List<HeritageMapSite> sites;
  final ValueChanged<String> onSiteTap;
  final DiscoveryLocation? userLocation;

  /// Testlerde ağ erişimi olmadan karo sunmak için kullanılabilir.
  /// Üretimde verilen sağlayıcı OSM önbellek politikasına uymalıdır.
  final TileProvider? tileProvider;

  // Web Mercator kutupları gösteremez. Coğrafi aralık doğrulamasına ek olarak
  // bu projeksiyon sınırının dışındaki konumları da güvenle atlıyoruz.
  static LatLng? _point(double? latitude, double? longitude) {
    if (!HeritageMapSite(
      id: '',
      name: '',
      latitude: latitude,
      longitude: longitude,
    ).hasValidCoordinates) {
      return null;
    }
    return LatLng(latitude!, longitude!);
  }

  @override
  Widget build(BuildContext context) {
    final validSites = <({HeritageMapSite site, LatLng point})>[];
    for (final site in sites) {
      final point = _point(site.latitude, site.longitude);
      if (point != null) validSites.add((site: site, point: point));
    }
    final userPoint = _point(userLocation?.latitude, userLocation?.longitude);
    final points = [for (final item in validSites) item.point, ?userPoint];
    if (points.isEmpty) {
      return const Center(
        child: Text('Haritada gösterilecek geçerli konum yok.'),
      );
    }
    final distinct = points.map((p) => (p.latitude, p.longitude)).toSet();
    return FlutterMap(
      // Veri sonradan değişirse kamera yeni konumlara göre yeniden kurulur.
      // Aynı verilerle üst widget rebuild olduğunda kullanıcının kamerası korunur.
      key: ValueKey(Object.hashAll(distinct)),
      options: MapOptions(
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        initialCenter: points.first,
        initialZoom: 16,
        maxZoom: 19,
        initialCameraFit: distinct.length > 1
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.all(56),
                maxZoom: 16,
              )
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hackathon.hackathon_kok',
          maxNativeZoom: 19,
          errorTileCallback: (tile, error, stackTrace) => onTileError?.call(),
          panBuffer: 0,
          // Varsayılan NetworkTileProvider, HTTP başlıklarına göre yerel
          // önbellek kullanır. Özel bir sağlayıcı verilmedikçe devre dışı bırakılmaz.
          tileProvider: tileProvider,
        ),
        MarkerLayer(
          markers: [
            for (final item in validSites)
              Marker(
                point: item.point,
                width: 48,
                height: 48,
                child: IconButton(
                  key: ValueKey('heritage-marker-${item.site.id}'),
                  tooltip: item.site.name,
                  onPressed: () => onSiteTap(item.site.id),
                  icon: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF7A2840),
                  ),
                ),
              ),
            if (userPoint != null)
              Marker(
                point: userPoint,
                width: 40,
                height: 40,
                child: const Tooltip(
                  message: 'Konumunuz',
                  child: Icon(
                    Icons.my_location,
                    key: ValueKey('heritage-user-marker'),
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: TextButton(
              key: const ValueKey('map-attribution'),
              child: const Text(
                '© OpenStreetMap contributors',
                textAlign: TextAlign.center,
              ),
              onPressed: () async {
                var opened = false;
                try {
                  opened = await launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  );
                } catch (_) {
                  // Tarayıcı bulunamaması harita etkileşimlerini bozmamalı.
                }
                if (!opened && context.mounted) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(
                      content: Text('Lisans bağlantısı açılamadı.'),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
