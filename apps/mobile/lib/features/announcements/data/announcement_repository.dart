import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/data/app_data_events.dart';
import '../../../shared/services/announcement_media_storage.dart';
import '../../../shared/services/private_pet_storage.dart';
import '../domain/breeding_announcement.dart';
import '../domain/community_announcement.dart';
import '../domain/sale_announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;
  static final List<BreedingAnnouncement> _breedingMock = [];
  static final List<SaleAnnouncement> _saleMock = [];
  static final List<CommunityAnnouncement> _communityMock = [];
  static const _pageSize = 30;
  static const _petProjection = '''
    id, owner_id, pet_id, announcement_type, contact_name, contact_phone,
    breed, pet_name, gender, birth_date, age_years, price_amount, photo_url,
    photo_storage_path, cover_photo_url, cover_photo_storage_path, color,
    has_vaccinations, has_pedigree, has_chip, desired_breed, conditions,
    description, city, status, created_at
  ''';
  static const _communityProjection = '''
    id, owner_id, announcement_type, title, address, event_date, contact_info,
    service_category, price_amount, website, offer_text, valid_from,
    valid_until, promo_code, cover_photo_url, cover_photo_storage_path,
    status, created_at
  ''';

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
        .select(_petProjection)
        .eq('announcement_type', 'breeding')
        .eq('status', 'active')
        .eq('moderation_status', 'published');
    if (breed != null && breed.isNotEmpty) {
      query = query.ilike('breed', '%$breed%');
    }
    if (city != null && city.isNotEmpty) query = query.ilike('city', '%$city%');
    final rows =
        await query.order('created_at', ascending: false).limit(_pageSize);
    final hydratedRows = await _hydrateMyPetPhotos(rows as List);
    return hydratedRows.map(BreedingAnnouncement.fromJson).toList();
  }

  Future<List<SaleAnnouncement>> getSaleAnnouncements(
      {String? breed, String? city}) async {
    if (_useMockData) return _filterSales(_saleMock, breed: breed, city: city);
    var query = _supabase
        .from('announcements')
        .select(_petProjection)
        .eq('announcement_type', 'sale')
        .eq('status', 'active')
        .eq('moderation_status', 'published');
    if (breed != null && breed.isNotEmpty) {
      query = query.ilike('breed', '%$breed%');
    }
    if (city != null && city.isNotEmpty) query = query.ilike('city', '%$city%');
    final rows =
        await query.order('created_at', ascending: false).limit(_pageSize);
    final hydratedRows = await _hydrateMyPetPhotos(rows as List);
    return hydratedRows.map(SaleAnnouncement.fromJson).toList();
  }

  Future<List<BreedingAnnouncement>> getBreedingAnnouncementsFiltered(
          {String? breed, String? city}) =>
      getBreedingAnnouncements(breed: breed, city: city);

  Future<List<SaleAnnouncement>> getMySaleAnnouncements(
      {required bool active}) async {
    if (_useMockData) {
      return _saleMock
          .where((item) =>
              item.ownerId == currentUserId && item.isActive == active)
          .toList();
    }
    final rows = await _supabase
        .from('announcements')
        .select(_petProjection)
        .eq('announcement_type', 'sale')
        .eq('owner_id', currentUserId!)
        .eq('status', active ? 'active' : 'inactive')
        .order('created_at', ascending: false)
        .limit(_pageSize);
    final hydratedRows = await _hydrateMyPetPhotos(rows as List);
    return hydratedRows.map(SaleAnnouncement.fromJson).toList();
  }

  Future<List<BreedingAnnouncement>> getMyBreedingAnnouncements(
      {required bool active}) async {
    if (_useMockData) {
      return _breedingMock
          .where((item) =>
              item.ownerId == currentUserId && item.isActive == active)
          .toList();
    }
    final rows = await _supabase
        .from('announcements')
        .select(_petProjection)
        .eq('announcement_type', 'breeding')
        .eq('owner_id', currentUserId!)
        .eq('status', active ? 'active' : 'inactive')
        .order('created_at', ascending: false)
        .limit(_pageSize);
    final hydratedRows = await _hydrateMyPetPhotos(rows as List);
    return hydratedRows.map(BreedingAnnouncement.fromJson).toList();
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
    AppDataEvents.notifyChanged();
  }

  Future<void> addBreedingAnnouncement(
      BreedingAnnouncement announcement) async {
    if (_useMockData) {
      _breedingMock.insert(0, announcement);
      return;
    }
    final userId = _requireUserId();
    await _supabase.from('announcements').insert(
          announcement.toInsertJson(currentOwnerId: userId),
        );
    AppDataEvents.notifyChanged();
  }

  Future<List<CommunityAnnouncement>> getCommunityAnnouncements(
    CommunityAnnouncementType type, {
    int page = 0,
    bool mine = false,
    bool active = true,
  }) async {
    if (_useMockData) {
      final userId = currentUserId;
      return _communityMock
          .where((item) =>
              item.type == type &&
              item.isActive == active &&
              (!mine || item.ownerId == userId))
          .skip(page * _pageSize)
          .take(_pageSize)
          .toList();
    }

    var query = _supabase
        .from('announcements')
        .select(_communityProjection)
        .eq('announcement_type', type.databaseValue)
        .eq('status', active ? 'active' : 'inactive');
    if (mine) {
      query = query.eq('owner_id', _requireUserId());
    } else {
      query = query.eq('moderation_status', 'published');
      final today = DateTime.now().toUtc().toIso8601String();
      if (type == CommunityAnnouncementType.event) {
        query = query.gte('event_date', today);
      } else if (type == CommunityAnnouncementType.offer) {
        query = query.gte('valid_until', today.split('T').first);
      }
    }
    final from = page * _pageSize;
    final rows = await query
        .order(
          type == CommunityAnnouncementType.event ? 'event_date' : 'created_at',
          ascending: type == CommunityAnnouncementType.event,
        )
        .range(from, from + _pageSize - 1);
    final hydrated = await _hydrateCommunityPhotos(rows as List);
    return hydrated.map(CommunityAnnouncement.fromJson).toList();
  }

  Future<List<CommunityAnnouncement>> getMyCommunityAnnouncements({
    required bool active,
  }) async {
    final groups = await Future.wait(
      CommunityAnnouncementType.values.map(
        (type) => getCommunityAnnouncements(
          type,
          mine: true,
          active: active,
        ),
      ),
    );
    final result = groups.expand((items) => items).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> addCommunityAnnouncement(
    CommunityAnnouncement announcement,
  ) async {
    if (_useMockData) {
      _communityMock.insert(0, announcement);
      AppDataEvents.notifyChanged();
      return;
    }
    await _supabase.from('announcements').insert(
          announcement.toJson(currentOwnerId: _requireUserId()),
        );
    AppDataEvents.notifyChanged();
  }

  Future<void> updateCommunityAnnouncement(
    CommunityAnnouncement announcement,
  ) async {
    if (_useMockData) {
      final index =
          _communityMock.indexWhere((item) => item.id == announcement.id);
      if (index >= 0) _communityMock[index] = announcement;
      AppDataEvents.notifyChanged();
      return;
    }
    await _updateOwnedAnnouncement(
      announcement.id,
      null,
      announcement.toUpdateJson(),
    );
  }

  Future<void> toggleCommunityActive(String id) => _toggleCommunityActive(id);

  Future<void> _toggleCommunityActive(String id) async {
    if (_useMockData) {
      final index = _communityMock.indexWhere((item) => item.id == id);
      if (index >= 0) {
        final item = _communityMock[index];
        _communityMock[index] = CommunityAnnouncement(
          id: item.id,
          type: item.type,
          title: item.title,
          address: item.address,
          createdAt: item.createdAt,
          eventDate: item.eventDate,
          contact: item.contact,
          serviceCategory: item.serviceCategory,
          priceAmount: item.priceAmount,
          website: item.website,
          offerText: item.offerText,
          validFrom: item.validFrom,
          validUntil: item.validUntil,
          promoCode: item.promoCode,
          photoUrl: item.photoUrl,
          photoStoragePath: item.photoStoragePath,
          isActive: !item.isActive,
          ownerId: item.ownerId,
        );
      }
      AppDataEvents.notifyChanged();
      return;
    }
    await _toggleActive(id, const <dynamic>[]);
  }

  Future<void> deleteCommunityAnnouncement(String id) =>
      _delete(id, _communityMock);

  Future<void> toggleSaleActive(String id) => _toggleActive(id, _saleMock);
  Future<void> toggleBreedingActive(String id) =>
      _toggleActive(id, _breedingMock);

  Future<void> _toggleActive(String id, List<dynamic> mockItems) async {
    if (_useMockData) {
      if (identical(mockItems, _saleMock)) {
        final index = _saleMock.indexWhere((item) => item.id == id);
        if (index >= 0) {
          final item = _saleMock[index];
          _saleMock[index] = SaleAnnouncement(
            id: item.id,
            ownerName: item.ownerName,
            phone: item.phone,
            breed: item.breed,
            puppyName: item.puppyName,
            gender: item.gender,
            birthDate: item.birthDate,
            price: item.price,
            photoUrl: item.photoUrl,
            photoStoragePath: item.photoStoragePath,
            petAvatarUrl: item.petAvatarUrl,
            petAvatarStoragePath: item.petAvatarStoragePath,
            color: item.color,
            hasVaccinations: item.hasVaccinations,
            hasPedigree: item.hasPedigree,
            hasChip: item.hasChip,
            notes: item.notes,
            location: item.location,
            createdAt: item.createdAt,
            isActive: !item.isActive,
            ownerId: item.ownerId,
            petId: item.petId,
          );
        }
      } else {
        final index = _breedingMock.indexWhere((item) => item.id == id);
        if (index >= 0) {
          final item = _breedingMock[index];
          _breedingMock[index] = BreedingAnnouncement(
            id: item.id,
            ownerName: item.ownerName,
            phone: item.phone,
            breed: item.breed,
            myDogName: item.myDogName,
            myDogGender: item.myDogGender,
            myDogAge: item.myDogAge,
            myDogPhotoUrl: item.myDogPhotoUrl,
            desiredBreed: item.desiredBreed,
            photoStoragePath: item.photoStoragePath,
            petAvatarUrl: item.petAvatarUrl,
            petAvatarStoragePath: item.petAvatarStoragePath,
            conditions: item.conditions,
            notes: item.notes,
            location: item.location,
            createdAt: item.createdAt,
            isActive: !item.isActive,
            ownerId: item.ownerId,
            petId: item.petId,
          );
        }
      }
      return;
    }
    final row = await _supabase
        .from('announcements')
        .select('status')
        .eq('id', id)
        .single();
    await _supabase.from('announcements').update({
      'status': row['status'] == 'active' ? 'inactive' : 'active',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    AppDataEvents.notifyChanged();
  }

  Future<void> deleteSaleAnnouncement(String id) => _delete(id, _saleMock);
  Future<void> deleteBreedingAnnouncement(String id) =>
      _delete(id, _breedingMock);

  Future<void> _delete(String id, List<dynamic> mockItems) async {
    if (_useMockData) {
      mockItems.removeWhere((dynamic item) => item.id == id);
      return;
    }
    await _supabase.from('announcements').delete().eq('id', id);
    AppDataEvents.notifyChanged();
  }

  Future<void> updateSaleAnnouncement(SaleAnnouncement updated) async {
    if (_useMockData) {
      final index = _saleMock.indexWhere((item) => item.id == updated.id);
      if (index >= 0) _saleMock[index] = updated;
      return;
    }
    await _updateOwnedAnnouncement(
      updated.id,
      updated.petId,
      updated.toUpdateJson(),
    );
  }

  Future<void> updateBreedingAnnouncement(BreedingAnnouncement updated) async {
    if (_useMockData) {
      final index = _breedingMock.indexWhere((item) => item.id == updated.id);
      if (index >= 0) _breedingMock[index] = updated;
      return;
    }
    await _updateOwnedAnnouncement(
      updated.id,
      updated.petId,
      updated.toUpdateJson(),
    );
  }

  Future<void> _updateOwnedAnnouncement(
    String id,
    String? petId,
    Map<String, dynamic> values,
  ) async {
    final userId = _requireUserId();
    var query = _supabase
        .from('announcements')
        .update({
          ...values,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('owner_id', userId);
    if (petId != null) {
      query = query.eq('pet_id', petId);
    }
    final updatedRow = await query.select('id').maybeSingle();

    if (updatedRow == null) {
      throw StateError(
        'The announcement was not updated for the current owner.',
      );
    }
    AppDataEvents.notifyChanged();
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

  Future<List<Map<String, dynamic>>> _hydrateMyPetPhotos(List rows) async {
    final result =
        rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
    await Future.wait(result.map((row) async {
      final coverStoragePath = row['cover_photo_storage_path'] as String? ??
          row['photo_storage_path'] as String?;
      if (coverStoragePath?.isNotEmpty == true) {
        try {
          row['cover_photo_url'] =
              await PrivatePetStorage.signedUrl(coverStoragePath);
        } catch (_) {
          // Keep the persisted fallback URL when signing is unavailable.
        }
      }

      final avatarStoragePath = row['photo_storage_path'] as String?;
      if (avatarStoragePath?.isNotEmpty == true) {
        try {
          row['pet_avatar_url'] =
              await PrivatePetStorage.signedUrl(avatarStoragePath);
          row['pet_avatar_storage_path'] = avatarStoragePath;
        } catch (_) {
          row['pet_avatar_url'] = row['photo_url'];
        }
      } else {
        row['pet_avatar_url'] = row['photo_url'];
      }
    }));
    return result;
  }

  Future<List<Map<String, dynamic>>> _hydrateCommunityPhotos(List rows) async {
    final result =
        rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
    await Future.wait(result.map((row) async {
      final path = row['cover_photo_storage_path'] as String?;
      if (path?.isNotEmpty != true) return;
      try {
        row['cover_photo_url'] = await AnnouncementMediaStorage.signedUrl(path);
      } catch (_) {
        // Keep the persisted fallback URL if signing is temporarily unavailable.
      }
    }));
    return result;
  }

  List<String> getBreedingBreeds() =>
      _sorted(_breedingMock.map((e) => e.breed));
  List<String> getSaleBreeds() => _sorted(_saleMock.map((e) => e.breed));
  List<String> getSaleCities() => _cities(_saleMock.map((e) => e.location));
  List<String> getBreedingCities() =>
      _cities(_breedingMock.map((e) => e.location));

  String _requireUserId() {
    final userId = currentUserId;
    if (userId == null) throw StateError('Потрібно увійти в акаунт.');
    return userId;
  }

  static List<SaleAnnouncement> _filterSales(List<SaleAnnouncement> items,
      {String? breed, String? city}) {
    final result = items
        .where((item) =>
            (breed == null ||
                breed.isEmpty ||
                item.breed.toLowerCase().contains(breed.toLowerCase())) &&
            (city == null ||
                city.isEmpty ||
                (item.location?.toLowerCase().contains(city.toLowerCase()) ??
                    false)))
        .toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  static List<BreedingAnnouncement> _filterBreeding(
      List<BreedingAnnouncement> items,
      {String? breed,
      String? city}) {
    final result = items
        .where((item) =>
            (breed == null ||
                breed.isEmpty ||
                item.breed.toLowerCase().contains(breed.toLowerCase())) &&
            (city == null ||
                city.isEmpty ||
                (item.location?.toLowerCase().contains(city.toLowerCase()) ??
                    false)))
        .toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  static List<String> _sorted(Iterable<String> values) =>
      (values.toSet().toList()..sort());
  static List<String> _cities(Iterable<String?> values) => _sorted(
      values.whereType<String>().map((value) => value.split(',').first.trim()));
}
