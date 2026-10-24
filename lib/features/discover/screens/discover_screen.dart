import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../data/models/heritage_site.dart';
import '../../../widgets/heritage_map.dart';
import '../../../data/repositories/heritage_site_repository.dart';
import '../../heritage_detail/screens/heritage_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.loadSites, this.mapTileProvider});

  /// Varsayılan olarak repository kullanılır; testlerde ağsız veri yüklenebilir.
  final Future<List<HeritageSite>> Function()? loadSites;

  final TileProvider? mapTileProvider;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late Future<List<HeritageSite>> _sitesFuture;
  bool _showMap = false;
  bool _tileError = false;

  @override
  void initState() {
    super.initState();
    _sitesFuture = _loadSites();
  }

  Future<List<HeritageSite>> _loadSites() =>
      widget.loadSites?.call() ??
      HeritageSiteRepository().fetchAll(cityId: 'bursa');

  void _retry() {
    setState(() {
      _sitesFuture = _loadSites();
    });
  }

  void _openDetail(HeritageSite site) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => HeritageDetailScreen(
          site: site,
          mapTileProvider: widget.mapTileProvider,
        ),
      ),
    );
  }

  Future<void> _showSite(HeritageSite site) async {
    final openDetail = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                site.displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('${site.type} · ${site.district}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Detayları gör'),
              ),
            ],
          ),
        ),
      ),
    );
    if (openDetail == true && mounted) _openDetail(site);
  }

  Widget _map(List<HeritageSite> sites) {
    final byId = {for (final site in sites) site.id: site};
    final points = [
      for (final site in sites)
        HeritageMapSite(
          id: site.id,
          name: site.displayName,
          latitude: site.latitude,
          longitude: site.longitude,
        ),
    ];
    final valid = points
        .where((site) => site.hasValidCoordinates)
        .toList(growable: false);
    if (valid.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Bu eserler için haritada gösterilebilecek geçerli konum bulunamadı. Eserlere Liste görünümünden ulaşabilirsiniz.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        if (_tileError)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Harita zemini yüklenemedi. İnternet bağlantınızı kontrol edin; eserlere Liste görünümünden ulaşabilirsiniz.',
            ),
          ),
        if (valid.length < sites.length)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '${sites.length - valid.length} eser konum bilgisi eksik veya geçersiz olduğu için yalnızca listede gösteriliyor.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: HeritageMap(
            sites: valid,
            onTileError: () {
              if (!_tileError && mounted) setState(() => _tileError = true);
            },
            tileProvider: widget.mapTileProvider,
            onSiteTap: (id) {
              final site = byId[id];
              if (site != null) _showSite(site);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HeritageSite>>(
      future: _sitesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Failed to load sites: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Eserler yüklenemedi.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _retry,
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          );
        }

        final sites = snapshot.data ?? [];
        if (sites.isEmpty) {
          return const Center(child: Text('Henüz eser yok.'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Liste'),
                    icon: Icon(Icons.list),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Harita'),
                    icon: Icon(Icons.map_outlined),
                  ),
                ],
                selected: {_showMap},
                onSelectionChanged: (selection) =>
                    setState(() => _showMap = selection.single),
              ),
            ),
            Expanded(
              child: _showMap
                  ? _map(sites)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sites.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final site = sites[index];
                        return ListTile(
                          onTap: () => _openDetail(site),
                          title: Text(site.displayName),
                          subtitle: Text('${site.type} · ${site.district}'),
                          trailing: const Icon(Icons.chevron_right),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
