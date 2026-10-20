import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

const _ink = Color(0xFF3E3028);

class HomeContent extends StatefulWidget {
  const HomeContent({super.key, required this.onStartDiscovery});

  final VoidCallback onStartDiscovery;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _city = 'Bursa';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: _ink),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: AppTheme.burgundy,
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _city,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: AppTheme.cream,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        items: ['Bursa', 'Konya', 'Hatay']
                            .map(
                              (city) => DropdownMenuItem(
                                value: city,
                                child: Text(city),
                              ),
                            )
                            .toList(),
                        onChanged: (city) {
                          if (city != null) setState(() => _city = city);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'KÜLTÜREL MİRASIN İZİNDE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.burgundy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ekrana Değil, Esere Bak',
                    style: TextStyle(
                      fontSize: 36,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Geçmişin izlerini keşfet, hikâyeleri yerinde yaşa.',
                    style: TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  const _HeritageVisual(hero: true),
                  const SizedBox(height: 32),
                  Text(
                    "$_city’dan Eserler",
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_city == 'Bursa') ...[
                    const Text(
                      'Örnek seçki • Konum bilgisi kullanılmıyor.',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const _HeritageCard(
                      name: 'Koza Han',
                      district: 'Osmangazi',
                    ),
                    const SizedBox(height: 12),
                    const _HeritageCard(
                      name: 'Yeşil Cami',
                      district: 'Yıldırım',
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_stories_outlined,
                            color: AppTheme.burgundy,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'İçerikler hazırlanıyor',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_city eserleri yakında burada yer alacak.',
                            style: const TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.burgundy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.route_outlined,
                          color: AppTheme.cream,
                          size: 32,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Keşif Zincirine Başla',
                          style: TextStyle(
                            color: AppTheme.cream,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Eserleri ziyaret et, görevleri tamamla, pasaportuna damga kazan.',
                          style: TextStyle(
                            color: AppTheme.cream,
                            height: 1.6,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: widget.onStartDiscovery,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Zinciri keşfet'),
                        ),
                      ],
                    ),
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

class _HeritageCard extends StatelessWidget {
  const _HeritageCard({required this.name, required this.district});

  final String name;
  final String district;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.burgundy.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeritageVisual(),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(district, style: const TextStyle(color: _ink)),
        ],
      ),
    );
  }
}

class _HeritageVisual extends StatelessWidget {
  const _HeritageVisual({this.hero = false});

  final bool hero;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hero ? 32 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAE0CD), Color(0xFFF3ECDF)],
        ),
        borderRadius: BorderRadius.circular(hero ? 28 : 14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: hero ? 72 : 40,
            color: AppTheme.burgundy,
          ),
          const SizedBox(height: 12),
          Text(
            hero ? 'Taşın, zamanın ve hikâyenin izinde' : 'Görsel hazırlanıyor',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: hero ? 14 : 11,
              height: 1.5,
            ),
          ),
          if (hero) ...[
            const SizedBox(height: 8),
            const Text(
              'Fotoğraf alanı • Görsel hazırlanıyor',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ink, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
