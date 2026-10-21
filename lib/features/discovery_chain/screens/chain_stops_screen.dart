import 'package:flutter/material.dart';

import '../../../data/models/chain.dart';
import '../../../data/models/chain_stop.dart';
import '../../../data/repositories/chain_repository.dart';

class ChainStopsScreen extends StatefulWidget {
  const ChainStopsScreen({super.key, required this.chain});

  final Chain chain;

  @override
  State<ChainStopsScreen> createState() => _ChainStopsScreenState();
}

class _ChainStopsScreenState extends State<ChainStopsScreen> {
  final _repository = ChainRepository();
  late Future<List<ChainStop>> _stopsFuture;

  @override
  void initState() {
    super.initState();
    _stopsFuture = _repository.fetchStops(widget.chain.id);
  }

  void _retry() {
    setState(() {
      _stopsFuture = _repository.fetchStops(widget.chain.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chain.name)),
      body: FutureBuilder<List<ChainStop>>(
        future: _stopsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Failed to load stops: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Duraklar yüklenemedi.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _retry,
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            );
          }

          final stops = snapshot.data ?? [];
          if (stops.isEmpty) {
            return const Center(child: Text('Bu zincirde henüz durak yok.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: stops.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final stop = stops[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${stop.order}')),
                title: Text(stop.site.displayName),
                subtitle: Text('${stop.site.type} · ${stop.site.district}'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          );
        },
      ),
    );
  }
}