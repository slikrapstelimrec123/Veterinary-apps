import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../pets/domain/pet.dart';
import '../domain/pet_transfer.dart';

class PetTransferRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<String?> sendTransfer({
    required Pet pet,
    required String toEmail,
    required String fromUserName,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (toEmail == 'notfound@test.com') {
        return '\u041a\u043e\u0440\u0438\u0441\u0442\u0443\u0432\u0430\u0447\u0430 \u0437 \u0442\u0430\u043a\u0438\u043c email \u043d\u0435 \u0437\u043d\u0430\u0439\u0434\u0435\u043d\u043e';
      }
      return null;
    }

    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return '\u041d\u0435 \u0430\u0432\u0442\u043e\u0440\u0438\u0437\u043e\u0432\u0430\u043d\u043e';
    }

    if (toEmail.toLowerCase() == currentUser.email?.toLowerCase()) {
      return '\u041d\u0435 \u043c\u043e\u0436\u043d\u0430 \u043f\u0435\u0440\u0435\u0434\u0430\u0442\u0438 \u0442\u0432\u0430\u0440\u0438\u043d\u0443 \u0441\u0430\u043c\u043e\u043c\u0443 \u0441\u043e\u0431\u0456';
    }

    final insertData = {
      'pet_id': pet.id,
      'from_user_id': currentUser.id,
      'to_email': toEmail.toLowerCase().trim(),
      'status': 'pending',
    };

    await _client.from('pet_transfers').insert(insertData);

    return null;
  }

  Future<List<PetTransfer>> getIncomingTransfers() async {
    if (_useMockData) return [];

    final email = _client.auth.currentUser?.email;
    if (email == null) return [];

    final rows = await _client
        .from('pet_transfers')
        .select('*, pets(name, species), profiles!from_user_id(full_name)')
        .eq('to_email', email.toLowerCase().trim())
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final pet = map['pets'] as Map<String, dynamic>?;
      final profile = map['profiles'] as Map<String, dynamic>?;
      return PetTransfer.fromJson({
        ...map,
        'pet_name': pet?['name'],
        'pet_species': pet?['species'],
        'from_user_name': profile?['full_name'],
      });
    }).toList();
  }

  Future<List<PetTransfer>> getOutgoingTransfers() async {
    if (_useMockData) return [];

    final rows = await _client
        .from('pet_transfers')
        .select('*, pets(name, species)')
        .eq('from_user_id', _client.auth.currentUser!.id)
        .inFilter('status', ['pending', 'accepted', 'declined']).order(
            'created_at',
            ascending: false);

    return (rows as List<dynamic>).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final pet = map['pets'] as Map<String, dynamic>?;
      return PetTransfer.fromJson({
        ...map,
        'pet_name': pet?['name'],
        'pet_species': pet?['species'],
      });
    }).toList();
  }

  Future<void> acceptTransfer(String transferId) async {
    await _client
        .rpc('accept_pet_transfer', params: {'transfer_id': transferId});
  }

  Future<void> declineTransfer(String transferId) async {
    await _client
        .rpc('decline_pet_transfer', params: {'transfer_id': transferId});
  }

  Future<void> cancelTransfer(String transferId) async {
    await _client
        .from('pet_transfers')
        .update({'status': 'cancelled'})
        .eq('id', transferId)
        .eq('from_user_id', _client.auth.currentUser!.id);
  }
}
