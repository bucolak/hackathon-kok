import 'package:flutter/material.dart';

import '../../../shared/widgets/journey_placeholder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const SafeArea(
        child: JourneyPlaceholder(
          icon: Icons.person_outline_rounded,
          title: 'Yolculuğun sana özel.',
          description: 'Profil bilgilerin ileride burada yer alacak.',
        ),
      ),
    );
  }
}
