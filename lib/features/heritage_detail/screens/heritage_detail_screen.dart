import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../data/models/heritage_site.dart';
import '../../../widgets/heritage_map.dart';

class HeritageDetailScreen extends StatelessWidget {
  const HeritageDetailScreen({
    super.key,
    required this.site,
    this.mapTileProvider,
  });

  final HeritageSite site;

  /// Ağsız widget testleri için; uygulamada varsayılan OSM sağlayıcısı kullanılır.
  final TileProvider? mapTileProvider;

  String _content(String? value, String fallback) =>
      value == null || value.trim().isEmpty ? fallback : value.trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _content(site.displayName, site.name);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Eser türü',
                    content: _content(
                      site.type,
                      'Eser türü bilgisi henüz eklenmemiş.',
                    ),
                  ),
                  _DetailSection(
                    title: 'İlçe',
                    content: _content(
                      site.district,
                      'İlçe bilgisi henüz eklenmemiş.',
                    ),
                  ),
                  _DetailSection(
                    title: 'Kısa açıklama',
                    content: _content(
                      site.summary,
                      'Bu eser için kısa açıklama henüz eklenmemiş.',
                    ),
                  ),
                  _DetailSection(
                    title: 'Tarihçe',
                    content: _content(
                      site.history,
                      'Bu eserin tarihçesi henüz eklenmemiş.',
                    ),
                  ),
                  _DetailSection(
                    title: 'Kaynak',
                    content: _content(
                      site.source,
                      'Kaynak bilgisi henüz eklenmemiş.',
                    ),
                  ),
                  Text(
                    'Haritadaki Konumu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (site.latitude.isFinite &&
                      site.longitude.isFinite &&
                      site.latitude.abs() <= 85.05112878 &&
                      site.longitude.abs() <= 180)
                    SizedBox(
                      key: const ValueKey('heritage-detail-map'),
                      height: 280,
                      width: double.infinity,
                      child: HeritageMap(
                        interactive: false,
                        tileProvider: mapTileProvider,
                        sites: [
                          HeritageMapSite(
                            id: site.id,
                            name: title,
                            latitude: site.latitude,
                            longitude: site.longitude,
                          ),
                        ],
                        onSiteTap: (_) {},
                      ),
                    )
                  else
                    const Text(
                      'Bu eserin haritada gösterilebilecek geçerli konum bilgisi bulunmuyor.',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
