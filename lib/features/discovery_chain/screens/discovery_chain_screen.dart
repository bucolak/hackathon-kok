import 'package:flutter/material.dart';

import '../../../shared/widgets/journey_placeholder.dart';

class DiscoveryChainScreen extends StatelessWidget {
  const DiscoveryChainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const JourneyPlaceholder(
      icon: Icons.route_outlined,
      title: 'İzleri birbirine bağla.',
      description: 'Keşiflerini bir araya getireceğin yolculuk zincirin burada yer alacak.',
    );
  }
}
