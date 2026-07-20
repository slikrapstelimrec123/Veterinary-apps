import 'community_announcement.dart';

class PetAnnouncementFilterOptions {
  const PetAnnouncementFilterOptions({
    required this.breeds,
    required this.cities,
  });

  final List<String> breeds;
  final List<String> cities;
}

class CommunityAnnouncementFilterOptions {
  const CommunityAnnouncementFilterOptions({
    required this.cities,
    required this.serviceCategories,
    required this.offerCategories,
  });

  final List<String> cities;
  final List<ServiceCategory> serviceCategories;
  final List<OfferCategory> offerCategories;
}

List<String> distinctFilterValues(Iterable<Object?> values) {
  final byNormalizedValue = <String, String>{};
  for (final value in values) {
    final displayValue = value?.toString().trim() ?? '';
    if (displayValue.isEmpty) continue;
    byNormalizedValue.putIfAbsent(
        displayValue.toLowerCase(), () => displayValue);
  }
  final result = byNormalizedValue.values.toList();
  result
      .sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
  return result;
}
