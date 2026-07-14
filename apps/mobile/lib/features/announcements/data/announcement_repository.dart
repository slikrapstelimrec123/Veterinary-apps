import '../domain/breeding_announcement.dart';
import '../domain/sale_announcement.dart';

class AnnouncementRepository {
  static final List<BreedingAnnouncement> _breedingMock = [];

  static final List<SaleAnnouncement> _saleMock = [];

  Future<List<BreedingAnnouncement>> getBreedingAnnouncements(
      {String? breed, String? city}) async {
    var list = List<BreedingAnnouncement>.from(_breedingMock);
    if (breed != null && breed.isNotEmpty) {
      list = list
          .where((a) => a.breed.toLowerCase().contains(breed.toLowerCase()))
          .toList();
    }
    if (city != null && city.isNotEmpty) {
      list = list
          .where((a) =>
              a.location != null &&
              a.location!.toLowerCase().contains(city.toLowerCase()))
          .toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<SaleAnnouncement>> getSaleAnnouncements(
      {String? breed, String? city}) async {
    var list = List<SaleAnnouncement>.from(_saleMock);
    if (breed != null && breed.isNotEmpty) {
      list = list
          .where((a) => a.breed.toLowerCase().contains(breed.toLowerCase()))
          .toList();
    }
    if (city != null && city.isNotEmpty) {
      list = list
          .where((a) =>
              a.location != null &&
              a.location!.toLowerCase().contains(city.toLowerCase()))
          .toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<BreedingAnnouncement>> getBreedingAnnouncementsFiltered(
      {String? breed, String? city}) async {
    var list = List<BreedingAnnouncement>.from(_breedingMock);
    if (breed != null && breed.isNotEmpty) {
      list = list
          .where((a) => a.breed.toLowerCase().contains(breed.toLowerCase()))
          .toList();
    }
    if (city != null && city.isNotEmpty) {
      list = list
          .where((a) =>
              a.location != null &&
              a.location!.toLowerCase().contains(city.toLowerCase()))
          .toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void addSaleAnnouncement(SaleAnnouncement announcement) {
    _saleMock.insert(0, announcement);
  }

  void addBreedingAnnouncement(BreedingAnnouncement announcement) {
    _breedingMock.insert(0, announcement);
  }

  static void toggleSaleActive(String id) {
    final i = _saleMock.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final a = _saleMock[i];
    _saleMock[i] = SaleAnnouncement(
      id: a.id,
      ownerName: a.ownerName,
      phone: a.phone,
      breed: a.breed,
      puppyName: a.puppyName,
      gender: a.gender,
      birthDate: a.birthDate,
      price: a.price,
      photoUrl: a.photoUrl,
      color: a.color,
      hasVaccinations: a.hasVaccinations,
      hasPedigree: a.hasPedigree,
      hasChip: a.hasChip,
      notes: a.notes,
      location: a.location,
      createdAt: a.createdAt,
      isActive: !a.isActive,
      ownerId: a.ownerId,
    );
  }

  static void deleteSaleAnnouncement(String id) {
    _saleMock.removeWhere((a) => a.id == id);
  }

  static void deleteBreedingAnnouncement(String id) {
    _breedingMock.removeWhere((a) => a.id == id);
  }

  static void updateSaleAnnouncement(SaleAnnouncement updated) {
    final i = _saleMock.indexWhere((a) => a.id == updated.id);
    if (i >= 0) _saleMock[i] = updated;
  }

  static void updateBreedingAnnouncement(BreedingAnnouncement updated) {
    final i = _breedingMock.indexWhere((a) => a.id == updated.id);
    if (i >= 0) _breedingMock[i] = updated;
  }

  static void toggleBreedingActive(String id) {
    final i = _breedingMock.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final a = _breedingMock[i];
    _breedingMock[i] = BreedingAnnouncement(
      id: a.id,
      ownerName: a.ownerName,
      phone: a.phone,
      breed: a.breed,
      myDogName: a.myDogName,
      myDogGender: a.myDogGender,
      myDogAge: a.myDogAge,
      myDogPhotoUrl: a.myDogPhotoUrl,
      desiredBreed: a.desiredBreed,
      conditions: a.conditions,
      notes: a.notes,
      location: a.location,
      createdAt: a.createdAt,
      isActive: !a.isActive,
      ownerId: a.ownerId,
    );
  }

  List<String> getBreedingBreeds() {
    final breeds = _breedingMock.map((a) => a.breed).toSet().toList()..sort();
    return breeds;
  }

  List<String> getSaleBreeds() {
    final breeds = _saleMock.map((a) => a.breed).toSet().toList()..sort();
    return breeds;
  }

  List<String> getSaleCities() {
    final cities = _saleMock
        .where((a) => a.location != null)
        .map((a) => a.location!.split(',').first.trim())
        .toSet()
        .toList()
      ..sort();
    return cities;
  }

  List<String> getBreedingCities() {
    final cities = _breedingMock
        .where((a) => a.location != null)
        .map((a) => a.location!.split(',').first.trim())
        .toSet()
        .toList()
      ..sort();
    return cities;
  }
}
