import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/data/app_data_events.dart';
import '../../../shared/services/announcement_media_storage.dart';
import '../../../shared/services/private_pet_storage.dart';
import '../domain/breeding_announcement.dart';
import '../domain/announcement_filter_options.dart';
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
    description, city, status, created_at, listing_credit_id, pets(species)
  ''';
  static const _communityProjection = '''
    id, owner_id, announcement_type, title, address, city, description,
    event_date, contact_info, service_category, offer_category, price_amount,
    website, offer_text, valid_from, valid_until, promo_code, cover_photo_url,
    cover_photo_storage_path, status, created_at, listing_credit_id,
    latitude, longitude
  ''';
  // Keep the catalogue usable while the location migration or PostgREST
  // schema cache is still being applied. Coordinates are optional in the
  // domain model and can be resolved from the address by the nearby filter.
  static const _legacyCommunityProjection = '''
    id, owner_id, announcement_type, title, address, city, description,
    event_date, contact_info, service_category, offer_category, price_amount,
    website, offer_text, valid_from, valid_until, promo_code, cover_photo_url,
    cover_photo_storage_path, status, created_at, listing_credit_id
  ''';

  bool get _useMockData => SupabaseConfig.useMockData;
  String? get currentUserId =>
      _useMockData ? 'mock_pet_owner' : _supabase.auth.currentUser?.id;

  Future<List<BreedingAnnouncement>> getBreedingAnnouncements(
      {String? breed, String? city, String? species}) async {
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
    if (city != null && city.isNotEmpty) {
      query = query.ilike('city', '%$city%');
    }
    if (species != null && species.isNotEmpty) {
      query = query.eq('pets.species', species);
    }
    final rows = await query
        .order('promoted_until', ascending: false, nullsFirst: false)
        .order('ranking_at', ascending: false)
        .limit(_pageSize);
    final hydratedRows = await _hydrateMyPetPhotos(rows as List);
    return hydratedRows.map(BreedingAnnouncement.fromJson).toList();
  }

  Future<List<SaleAnnouncement>> getSaleAnnouncements(
      {String? breed, String? city, String? species}) async {
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
    if (city != null && city.isNotEmpty) {
      query = query.ilike('city', '%$city%');
    }
    if (species != null && species.isNotEmpty) {
      query = query.eq('pets.species', species);
    }
    final rows = await query
        .order('promoted_until', ascending: false, nullsFirst: false)
        .order('ranking_at', ascending: false)
        .limit(_pageSize);
    final hydratedRows = await _hydrateMyPetPhotos(rows as List);
    return hydratedRows.map(SaleAnnouncement.fromJson).toList();
  }

  Future<PetAnnouncementFilterOptions> getPetAnnouncementFilterOptions(
    String announcementType,
  ) async {
    if (_useMockData) {
      final breeds = announcementType == 'breeding'
          ? _breedingMock.map((item) => item.breed)
          : _saleMock.map((item) => item.breed);
      final cities = announcementType == 'breeding'
          ? _breedingMock.map((item) => item.location)
          : _saleMock.map((item) => item.location);
      return PetAnnouncementFilterOptions(
        breeds: distinctFilterValues(breeds),
        cities: distinctFilterValues(cities),
        species: const [],
      );
    }
    final rows = await _supabase
        .from('announcements')
        .select('breed, city, pets(species)')
        .eq('announcement_type', announcementType)
        .eq('status', 'active')
        .eq('moderation_status', 'published')
        .limit(1000);
    final maps = (rows as List).cast<Map<String, dynamic>>();
    return PetAnnouncementFilterOptions(
      breeds: distinctFilterValues(maps.map((row) => row['breed'])),
      cities: distinctFilterValues(maps.map((row) => row['city'])),
      species: distinctFilterValues(maps
          .map((row) => (row['pets'] as Map<String, dynamic>?)?['species'])),
    );
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
    await _attachOwnerMetrics(hydratedRows);
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
    await _attachOwnerMetrics(hydratedRows);
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
    String? city,
    ServiceCategory? serviceCategory,
    OfferCategory? offerCategory,
    int? pageSize,
  }) async {
    final size = pageSize ?? _pageSize;
    if (_useMockData) {
      final userId = currentUserId;
      return _communityMock
          .where((item) =>
              item.type == type &&
              item.isActive == active &&
              (!mine || item.ownerId == userId) &&
              (city == null || city.isEmpty || item.city == city) &&
              (serviceCategory == null ||
                  item.serviceCategory == serviceCategory) &&
              (offerCategory == null || item.offerCategory == offerCategory))
          .skip(page * size)
          .take(size)
          .toList();
    }

    final rows = await _fetchCommunityRows(
      type: type,
      page: page,
      size: size,
      mine: mine,
      active: active,
      city: city,
      serviceCategory: serviceCategory,
      offerCategory: offerCategory,
    );
    final hydrated = await _hydrateCommunityPhotos(rows);
    if (mine) await _attachOwnerMetrics(hydrated);
    return hydrated.map(CommunityAnnouncement.fromJson).toList();
  }

  Future<List<dynamic>> _fetchCommunityRows({
    required CommunityAnnouncementType type,
    required int page,
    required int size,
    required bool mine,
    required bool active,
    required String? city,
    required ServiceCategory? serviceCategory,
    required OfferCategory? offerCategory,
  }) async {
    Future<List<dynamic>> execute(String projection) async {
      var query = _supabase
          .from('announcements')
          .select(projection)
          .eq('announcement_type', type.databaseValue)
          .eq('status', active ? 'active' : 'inactive');
      if (mine) {
        query = query.eq('owner_id', _requireUserId());
      } else {
        // Published announcements are public. The owner must also be able to
        // see every one of their active records in the public list while a
        // moderation review is pending; this does not expose another user's
        // unpublished content.
        final ownerId = currentUserId;
        if (ownerId == null) {
          query = query.eq('moderation_status', 'published');
        }
        final today = DateTime.now().toUtc().toIso8601String();
        if (type == CommunityAnnouncementType.event) {
          if (ownerId == null) {
            query = query.gte('event_date', today);
          } else {
            query = query.or(
              'and(moderation_status.eq.published,event_date.gte.$today),'
              'owner_id.eq.$ownerId',
            );
          }
        } else if (type == CommunityAnnouncementType.offer) {
          final validUntil = today.split('T').first;
          if (ownerId == null) {
            query = query.gte('valid_until', validUntil);
          } else {
            query = query.or(
              'and(moderation_status.eq.published,valid_until.gte.$validUntil),'
              'owner_id.eq.$ownerId',
            );
          }
        } else if (ownerId != null) {
          query = query.or(
            'moderation_status.eq.published,owner_id.eq.$ownerId',
          );
        }
      }
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }
      if (serviceCategory != null) {
        query = query.eq('service_category', serviceCategory.databaseValue);
      }
      if (offerCategory != null) {
        query = query.eq('offer_category', offerCategory.databaseValue);
      }
      final from = page * size;
      final result = type == CommunityAnnouncementType.event
          ? await query
              .order('event_date', ascending: true)
              .range(from, from + size - 1)
          : await query
              .order('promoted_until', ascending: false, nullsFirst: false)
              .order('ranking_at', ascending: false)
              .range(from, from + size - 1);
      return (result as List).cast<dynamic>();
    }

    try {
      return await execute(_communityProjection);
    } on PostgrestException catch (error) {
      if (!_isMissingLocationColumns(error)) rethrow;
      return execute(_legacyCommunityProjection);
    }
  }

  bool _isMissingLocationColumns(PostgrestException error) {
    final details = '${error.code} ${error.message}'.toLowerCase();
    return details.contains('latitude') || details.contains('longitude');
  }

  Future<CommunityAnnouncementFilterOptions>
      getCommunityAnnouncementFilterOptions(
    CommunityAnnouncementType type,
  ) async {
    if (_useMockData) {
      final items = _communityMock.where(
        (item) => item.type == type && item.isActive,
      );
      return CommunityAnnouncementFilterOptions(
        cities: distinctFilterValues(items.map((item) => item.city)),
        serviceCategories: ServiceCategory.values
            .where((category) => items.any(
                  (item) => item.serviceCategory == category,
                ))
            .toList(),
        offerCategories: OfferCategory.values
            .where((category) => items.any(
                  (item) => item.offerCategory == category,
                ))
            .toList(),
      );
    }

    var query = _supabase
        .from('announcements')
        .select('city, service_category, offer_category')
        .eq('announcement_type', type.databaseValue)
        .eq('status', 'active');
    final ownerId = currentUserId;
    if (ownerId == null) {
      query = query.eq('moderation_status', 'published');
    }
    final today = DateTime.now().toUtc().toIso8601String();
    if (type == CommunityAnnouncementType.event) {
      if (ownerId == null) {
        query = query.gte('event_date', today);
      } else {
        query = query.or(
          'and(moderation_status.eq.published,event_date.gte.$today),'
          'owner_id.eq.$ownerId',
        );
      }
    } else if (type == CommunityAnnouncementType.offer) {
      final validUntil = today.split('T').first;
      if (ownerId == null) {
        query = query.gte('valid_until', validUntil);
      } else {
        query = query.or(
          'and(moderation_status.eq.published,valid_until.gte.$validUntil),'
          'owner_id.eq.$ownerId',
        );
      }
    } else if (ownerId != null) {
      query = query.or(
        'moderation_status.eq.published,owner_id.eq.$ownerId',
      );
    }
    final rows = await query.limit(1000);
    final maps = (rows as List).cast<Map<String, dynamic>>();
    final serviceValues = maps
        .map((row) => ServiceCategory.fromDatabase(
              row['service_category'] as String?,
            ))
        .whereType<ServiceCategory>()
        .toSet();
    final offerValues = maps
        .map((row) => OfferCategory.fromDatabase(
              row['offer_category'] as String?,
            ))
        .whereType<OfferCategory>()
        .toSet();
    return CommunityAnnouncementFilterOptions(
      cities: distinctFilterValues(maps.map((row) => row['city'])),
      serviceCategories:
          ServiceCategory.values.where(serviceValues.contains).toList(),
      offerCategories:
          OfferCategory.values.where(offerValues.contains).toList(),
    );
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
    final values = announcement.toJson(currentOwnerId: _requireUserId());
    try {
      await _supabase.from('announcements').insert(values);
    } on PostgrestException catch (error) {
      if (!_isMissingLocationColumns(error)) rethrow;
      values
        ..remove('latitude')
        ..remove('longitude');
      await _supabase.from('announcements').insert(values);
    }
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
          city: item.city,
          description: item.description,
          createdAt: item.createdAt,
          eventDate: item.eventDate,
          contact: item.contact,
          serviceCategory: item.serviceCategory,
          offerCategory: item.offerCategory,
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
          viewCount: item.viewCount,
          listingCreditId: item.listingCreditId,
          latitude: item.latitude,
          longitude: item.longitude,
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
            viewCount: item.viewCount,
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
            viewCount: item.viewCount,
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
    final payload = {
      ...values,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    Future<Map<String, dynamic>?> executeUpdate() async {
      var query = _supabase
          .from('announcements')
          .update(payload)
          .eq('id', id)
          .eq('owner_id', userId);
      if (petId != null) {
        query = query.eq('pet_id', petId);
      }
      return query.select('id').maybeSingle();
    }

    Map<String, dynamic>? updatedRow;
    try {
      updatedRow = await executeUpdate();
    } on PostgrestException catch (error) {
      if (!_isMissingLocationColumns(error)) rethrow;
      payload
        ..remove('latitude')
        ..remove('longitude');
      updatedRow = await executeUpdate();
    }

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

  Future<void> recordAnnouncementView(String announcementId) async {
    if (_useMockData) return;
    await _supabase.rpc(
      'record_announcement_view',
      params: {'p_announcement_id': announcementId},
    );
  }

  Future<void> _attachOwnerMetrics(
    List<Map<String, dynamic>> rows,
  ) async {
    if (_useMockData || rows.isEmpty) return;
    final ids = rows.map((row) => row['id'] as String).toList();
    final metricRows = await _supabase
        .from('announcement_owner_metrics')
        .select('announcement_id, view_count')
        .inFilter('announcement_id', ids);
    final metrics = <String, int>{
      for (final row in metricRows as List)
        row['announcement_id'] as String:
            (row['view_count'] as num?)?.toInt() ?? 0,
    };
    for (final row in rows) {
      row['view_count'] = metrics[row['id']] ?? 0;
    }
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
}
