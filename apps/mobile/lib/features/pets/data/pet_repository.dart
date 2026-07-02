import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/data/mock_data.dart';
import '../domain/pet.dart';

class PetRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Pet>> getPets() async {
    if (_useMockData) {
      return MockData.pets;
    }

    final data = await _client
        .from('pets')
        .select('*')
        .eq('owner_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return (data as List<dynamic>).map((row) => Pet.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<Pet?> getPet(String id) async {
    if (_useMockData) {
      for (final pet in MockData.pets) {
        if (pet.id == id) {
          return pet;
        }
      }
      return null;
    }

    final data = await _client.from('pets').select('*').eq('id', id).maybeSingle();
    return data == null ? null : Pet.fromJson(data);
  }

  Future<Pet> createPet(Pet pet) async {
    if (_useMockData) {
      final created = pet.copyWith(id: 'mock_pet_${DateTime.now().millisecondsSinceEpoch}');
      MockData.pets.add(created);
      return created;
    }

    final insertData = {
      ...pet.toInsertJson(),
      'owner_id': _client.auth.currentUser!.id,
    };
    final created = await _client.from('pets').insert(insertData).select('*').single();
    return Pet.fromJson(created);
  }

  Future<Pet> updatePet(Pet pet) async {
    if (_useMockData) {
      final index = MockData.pets.indexWhere((item) => item.id == pet.id);
      if (index >= 0) {
        MockData.pets[index] = pet;
      }
      return pet;
    }

    final updated = await _client.from('pets').update(pet.toInsertJson()).eq('id', pet.id).select('*').single();
    return Pet.fromJson(updated);
  }
}
