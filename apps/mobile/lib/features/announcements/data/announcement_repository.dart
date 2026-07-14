import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/breeding_announcement.dart';
import '../domain/sale_announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;
  static final List<BreedingAnnouncement> _breedingMock = [];
  static final List<SaleAnnouncement> _saleMock = [];

  bool get _useMockData => SupabaseConfig.useMockData;
  String? get currentUserId =>
      _useMockData ? 'mock_pet_owner' : _supabase.auth.currentUser?.id;

  Future<List<BreedingAnnouncement>> getBreedingAnnouncements(
      {String? breed, String? city}) async {
    if (_useMockData) {
      return _filterBreeding(_breedingMock, breed: breed, city: city);
    }
    var query = _supabase
        .from('announcements')
        .select()
        .eq('announcement_type', 'breeding')
        .eq('status', 'active')
        .eq('moderation_status', 'published');
    if (breed != null && breed.isNotEmpty) query = query.ilike('breed', '%$breed%');
    if (city != null && city.isNotEmpty) query = query.ilike('city', '%$city%');
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((row) => BreedingAnnouncement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<SaleAnnouncement>> getSaleAnnouncements(
      {String? breed, String? city}) async {
    if (_useMockData) return _filterSales(_saleMock, breed: breed, city: city);
    var query = _supabase
        .from('announcements')
        .select()
        .eq('announcement_type', 'sale')
        .eq('status', 'active')
        .eq('moderation_status', 'published');
    if (breed != null && breed.isNotEmpty) query = query.ilike('breed', '%$breed%');
    if (city != null && city.isNotEmpty) query = query.ilike('city', '%$city%');
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((row) => SaleAnnouncement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<BreedingAnnouncement>> getBreedingAnnouncementsFiltered(
          {String? breed, String? city}) =>
      getBreedingAnnouncements(breed: breed, city: city);

  Future<List<SaleAnnouncement>> getMySaleAnnouncements(
      {required bool active}) async {
    if (_useMockData) {
      return _saleMock
          .where((item) => item.ownerId == currentUserId && item.isActive == active)
          .toList();
    }
    final rows = await _supabase
        .from('announcements')
        .select()
        .eq('announcement_type', 'sale')
        .eq('owner_id', currentUserId!)
        .eq('status', active ? 'active' : 'inactive')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => SaleAnnouncement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<BreedingAnnouncement>> getMyBreedingAnnouncements(
      {required bool active}) async {
    if (_useMockData) {
      return _breedingMock
          .where((item) => item.ownerId == currentUserId && item.isActive == active)
          .toList();
    }
    final rows = await _supabase
        .from('announcements')
        .select()
        .eq('announcement_type', 'breeding')
        .eq('owner_id', currentUserId!)
        .eq('status', active ? 'active' : 'inactive')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => BreedingAnnouncement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> addSaleAnnouncement(SaleAnnouncement announcement) async {
    if (_useMockData) {
      _saleMock.insert(0, announcement);
      return;
    }
    final userId = _requireUserId();
    await _supabase.from('announcements').insert(
          announcement.toInsertJson(currentOwnerId: userId),
        );
  }

  Future<void> addBreedingAnnouncement(BreedingAnnouncement announcement) async {
    if (_useMockData) {
      _breedingMock.insert(0, announcement);
      return;
    }
    final userId = _requireUserId();
    await _supabase.from('announcements').insert(
          announcement.toInsertJson(currentOwnerId: userId),
        );
  }

  Future<void> toggleSaleActive(String id) => _toggleActive(id, _saleMock);
  Future<void> toggleBreedingActive(String id) => _toggleActive(id, _breedingMock);

  Future<void> _toggleActive(String id, List<dynamic> mockItems) async {
    if (_useMockData) {
      if (identical(mockItems, _saleMock)) {
        final index = _saleMock.indexWhere((item) => item.id == id);
        if (index >= 0) {
          final item = _saleMock[index];
          _saleMock[index] = SaleAnnouncement(
            id: item.id, ownerName: item.ownerName, phone: item.phone,
            breed: item.breed, puppyName: item.puppyName, gender: item.gender,
            birthDate: item.birthDate, price: item.price, photoUrl: item.photoUrl,
            color: item.color, hasVaccinations: item.hasVaccinations,
            hasPedigree: item.hasPedigree, hasChip: item.hasChip,
            notes: item.notes, location: item.location, createdAt: item.createdAt,
            isActive: !item.isActive, ownerId: item.ownerId, petId: item.petId,
          );
        }
      } else {
        final index = _breedingMock.indexWhere((item) => item.id == id);
        if (index >= 0) {
          final item = _breedingMock[index];
          _breedingMock[index] = BreedingAnnouncement(
            id: item.id, ownerName: item.ownerName, phone: item.phone,
            breed: item.breed, myDogName: item.myDogName,
            myDogGender: item.myDogGender, myDogAge: item.myDogAge,
            myDogPhotoUrl: item.myDogPhotoUrl, desiredBreed: item.desiredBreed,
            conditions: item.conditions, notes: item.notes,
            location: item.location, createdAt: item.createdAt,
            isActive: !item.isActive, ownerId: item.ownerId, petId: item.petId,
          );
        }
      }
      return;
    }
    final row = await _supabase.from('announcements').select('status').eq('id', id).single();
    await _supabase.from('announcements').update({
      'status': row['status'] == 'active' ? 'inactive' : 'active',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteSaleAnnouncement(String id) => _delete(id, _saleMock);
  Future<void> deleteBreedingAnnouncement(String id) => _delete(id, _breedingMock);

  Future<void> _delete(String id, List<dynamic> mockItems) async {
    if (_useMockData) {
      mockItems.removeWhere((dynamic item) => item.id == id);
      return;
    }
    await _supabase.from('announcements').delete().eq('id', id);
  }

  Future<void> updateSaleAnnouncement(SaleAnnouncement updated) async {
    if (_useMockData) {
      final index = _saleMock.indexWhere((item) => item.id == updated.id);
      if (index >= 0) _saleMock[index] = updated;
      return;
    }
    await _supabase.from('announcements').update({
      'breed': updated.breed,
      'pet_name': updated.puppyName,
      'price_amount': updated.price,
      'description': updated.notes,
      'city': updated.location,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', updated.id);
  }

  Future<void> updateBreedingAnnouncement(BreedingAnnouncement updated) async {
    if (_useMockData) {
      final index = _breedingMock.indexWhere((item) => item.id == updated.id);
      if (index >= 0) _breedingMock[index] = updated;
      return;
    }
    await _supabase.from('announcements').update({
      'breed': updated.breed,
      'pet_name': updated.myDogName,
      'conditions': updated.conditions,
      'description': updated.notes,
      'city': updated.location,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', updated.id);
  }

  Future<void> reportAnnouncement(String id, {String reason = 'other'}) async {
    if (_useMockData) return;
    await _supabase.from('announcement_reports').insert({
      'announcement_id': id,
      'reporter_id': _requireUserId(),
      'reason': reason,
    });
  }

  Future<void> blockOwner(String ownerId) async {
    if (_useMockData) return;
    await _supabase.from('announcement_user_blocks').upsert({
      'blocker_id': _requireUserId(),
      'blocked_user_id': ownerId,
    });
  }

  List<String> getBreedingBreeds() => _sorted(_breedingMock.map((e) => e.breed));
  List<String> getSaleBreeds() => _sorted(_saleMock.map((e) => e.breed));
  List<String> getSaleCities() => _cities(_saleMock.map((e) => e.location));
  List<String> getBreedingCities() => _cities(_breedingMock.map((e) => e.location));

  String _requireUserId() {
    final userId = currentUserId;
    if (userId == null) throw StateError('Потрібно увійти в акаунт.');
    return userId;
  }

  static List<SaleAnnouncement> _filterSales(List<SaleAnnouncement> items,
      {String? breed, String? city}) {
    final result = items.where((item) =>
        (breed == null || breed.isEmpty || item.breed.toLowerCase().contains(breed.toLowerCase())) &&
        (city == null || city.isEmpty || (item.location?.toLowerCase().contains(city.toLowerCase()) ?? false))).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  static List<BreedingAnnouncement> _filterBreeding(List<BreedingAnnouncement> items,
      {String? breed, String? city}) {
    final result = items.where((item) =>
        (breed == null || breed.isEmpty || item.breed.toLowerCase().contains(breed.toLowerCase())) &&
        (city == null || city.isEmpty || (item.location?.toLowerCase().contains(city.toLowerCase()) ?? false))).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  static List<String> _sorted(Iterable<String> values) =>
      (values.toSet().toList()..sort());
  static List<String> _cities(Iterable<String?> values) =>
      _sorted(values.whereType<String>().map((value) => value.split(',').first.trim()));
}
