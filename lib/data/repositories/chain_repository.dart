import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chain_stop.dart';
import '../models/chain.dart';

class ChainRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Chain>> fetchAll({String cityId = 'bursa'}) async {
    final rows = await _client
        .from('zincirler')
        .select()
        .eq('sehir_id', cityId)
        .eq('yayinda', true)
        .order('id', ascending: true);
    return rows.map(Chain.fromMap).toList();
  }

  Future<List<ChainStop>> fetchStops(String chainId) async {
    final rows = await _client
        .from('zincir_duraklari')
        .select('*, eserler(*)')
        .eq('zincir_id', chainId)
        .order('sira', ascending: true);
    return rows.map(ChainStop.fromMap).toList();
  }
}