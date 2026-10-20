import 'package:flutter/material.dart';

import '../../../shared/widgets/journey_placeholder.dart';

class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const JourneyPlaceholder(
      icon: Icons.book_outlined,
      title: 'Yolculuğunun izlerini biriktir.',
      description:
          'Keşiflerin ve yolculuk hatıraların ileride pasaportunda yer alacak.',
    );
  }
}
