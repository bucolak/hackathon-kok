import 'package:flutter/material.dart';
import 'chain_stops_screen.dart';
import '../../../data/models/chain.dart';
import '../../../data/repositories/chain_repository.dart';

class DiscoveryChainScreen extends StatefulWidget {
  const DiscoveryChainScreen({super.key});

  @override
  State<DiscoveryChainScreen> createState() => _DiscoveryChainScreenState();
}

class _DiscoveryChainScreenState extends State<DiscoveryChainScreen> {
  final _repository = ChainRepository();
  late Future<List<Chain>> _chainsFuture;

  @override
  void initState() {
    super.initState();
    _chainsFuture = _repository.fetchAll();
  }

  void _retry() {
    setState(() {
      _chainsFuture = _repository.fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Chain>>(
      future: _chainsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Failed to load chains: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Zincirler yüklenemedi.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _retry,
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          );
        }

        final chains = snapshot.data ?? [];
        if (chains.isEmpty) {
          return const Center(child: Text('Henüz zincir yok.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: chains.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ChainCard(chain: chains[index]),
        );
      },
    );
  }
}

class _ChainCard extends StatelessWidget {
  const _ChainCard({required this.chain});

  final Chain chain;

  String get _distanceText {
    final km = chain.distanceMeters / 1000;
    return '~${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChainStopsScreen(chain: chain),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(chain.name, style: textTheme.titleLarge),
              if (chain.theme != null) ...[
                const SizedBox(height: 4),
                Text(chain.theme!, style: textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.directions_walk, size: 18),
                  const SizedBox(width: 4),
                  Text('$_distanceText · ${chain.durationMinutes} dk'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}