import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/heritage_site.dart';

class HeritageSiteRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<HeritageSite>> fetchAll({String cityId = 'bursa'}) async {
    final rows = await _client
        .from('eserler')
        .select()
        .eq('sehir_id', cityId)
        .eq('yayinda', true)
        .order('id', ascending: true);

    return rows.map(HeritageSite.fromMap).toList();
  }
}