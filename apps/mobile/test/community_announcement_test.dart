import 'package:flutter_test/flutter_test.dart';
import 'package:vet_care_mobile/features/announcements/domain/community_announcement.dart';

void main() {
  test('event announcement maps only event fields', () {
    final event = CommunityAnnouncement(
      id: '00000000-0000-4000-8000-000000000001',
      type: CommunityAnnouncementType.event,
      title: 'День адопції',
      address: 'Київ, парк',
      createdAt: DateTime.utc(2026, 7, 19),
      eventDate: DateTime.utc(2026, 8, 1),
      contact: '+380000000000',
      photoStoragePath: 'owner/event/photo.jpg',
    );

    final json = event.toJson(currentOwnerId: 'owner-id');

    expect(json['announcement_type'], 'event');
    expect(json['pet_id'], isNull);
    expect(json['event_date'], isNotNull);
    expect(json['service_category'], isNull);
    expect(json['offer_text'], isNull);
  });

  test('service category round-trips from database', () {
    final service = CommunityAnnouncement.fromJson({
      'id': '00000000-0000-4000-8000-000000000002',
      'announcement_type': 'service',
      'title': 'Догляд за собакою',
      'address': 'Львів',
      'service_category': 'pet_sitter',
      'price_amount': 500,
      'status': 'active',
      'created_at': '2026-07-19T10:00:00Z',
    });

    expect(service.serviceCategory, ServiceCategory.petSitter);
    expect(service.subtitle, contains('Петсіттер'));
    expect(service.subtitle, contains('500 грн'));
  });

  test('offer maps validity and promo code', () {
    final offer = CommunityAnnouncement.fromJson({
      'id': '00000000-0000-4000-8000-000000000003',
      'announcement_type': 'offer',
      'title': 'Знижка на корм',
      'address': 'Онлайн',
      'offer_text': 'Знижка 15%',
      'valid_from': '2026-07-19',
      'valid_until': '2026-08-19',
      'promo_code': 'LAPPO15',
      'status': 'active',
      'created_at': '2026-07-19T10:00:00Z',
    });

    expect(offer.validUntil, DateTime(2026, 8, 19));
    expect(offer.promoCode, 'LAPPO15');
  });
}
