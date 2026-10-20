import 'package:flutter/material.dart';

import '../../../shared/widgets/journey_placeholder.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const JourneyPlaceholder(
      icon: Icons.explore_outlined,
      title: 'Yeni hikâyelere açıl.',
      description:
          'Kültürel mirası keşfedeceğin içerikler ileride burada yer alacak.',
    );
  }
}
