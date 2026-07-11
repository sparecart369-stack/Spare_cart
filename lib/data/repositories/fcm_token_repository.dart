import 'package:supabase_flutter/supabase_flutter.dart';

class FcmTokenRepository {
  FcmTokenRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) return;
    await _client.rpc('add_fcm_token', params: {'token': token.trim()});
  }

  Future<void> removeToken(String token) async {
    if (token.trim().isEmpty) return;
    await _client.rpc('remove_fcm_token', params: {'token': token.trim()});
  }
}
