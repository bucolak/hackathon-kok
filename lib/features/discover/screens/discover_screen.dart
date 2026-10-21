import 'package:flutter/material.dart';

import '../../../data/models/heritage_site.dart';
import '../../../data/repositories/heritage_site_repository.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _repository = HeritageSiteRepository();
  late Future<List<HeritageSite>> _sitesFuture;

  @override
  void initState() {
    super.initState();
    _sitesFuture = _repository.fetchAll();
  }

  void _retry() {
    setState(() {
      _sitesFuture = _repository.fetchAll();
    });
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

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sites.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final site = sites[index];
            return ListTile(
              title: Text(site.displayName),
              subtitle: Text('${site.type} · ${site.district}'),
              trailing: const Icon(Icons.chevron_right),
            );
          },
        );
      },
    );
  }
}