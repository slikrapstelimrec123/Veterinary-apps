import 'package:flutter_test/flutter_test.dart';
import 'package:vet_care_mobile/features/achievements/data/achievement_repository.dart';
import 'package:vet_care_mobile/features/achievements/domain/pet_achievement.dart';
import 'package:vet_care_mobile/features/feeding/data/feeding_repository.dart';
import 'package:vet_care_mobile/features/feeding/domain/pet_feeding.dart';
import 'package:vet_care_mobile/features/medications/data/medication_repository.dart';
import 'package:vet_care_mobile/features/medications/domain/pet_medication.dart';
import 'package:vet_care_mobile/features/notifications/domain/app_notification.dart';
import 'package:vet_care_mobile/features/visit_records/domain/visit_record.dart';

void main() {
  const petId = 'scenario-pet';

  test('feeding can be created and edited in the owner flow', () async {
    final repository = FeedingRepository();
    final created = await repository.addFeeding(PetFeeding(
      id: '',
      petId: petId,
      foodName: 'Starter',
      startDate: DateTime(2026, 7, 1),
    ));

    final updated = await repository.updateFeeding(PetFeeding(
      id: created.id,
      petId: petId,
      foodName: 'Adult',
      startDate: created.startDate,
      rating: 5,
    ));

    expect(updated.foodName, 'Adult');
    expect((await repository.getFeedings(petId)).single.rating, 5);
  });

  test('medication edits preserve reminder details', () async {
    final repository = MedicationRepository();
    final created = await repository.addMedication(PetMedication(
      id: '',
      petId: petId,
      name: 'Vitamin',
      givenDate: DateTime(2026, 7, 1),
    ));
    final nextDose = DateTime(2026, 8, 1);

    final updated = await repository.updateMedication(PetMedication(
      id: created.id,
      petId: petId,
      name: 'Vitamin D',
      givenDate: created.givenDate,
      nextDoseDate: nextDose,
      reminderEnabled: true,
    ));

    expect(updated.reminderEnabled, isTrue);
    expect(updated.nextDoseDate, nextDose);
  });

  test('event stores private image paths used for signed URLs', () async {
    final repository = AchievementRepository();
    final created = await repository.addAchievement(PetAchievement(
      id: '',
      petId: petId,
      title: 'Training',
      eventDate: DateTime(2026, 7, 2),
      awardImagePath: 'owner/$petId/award.jpg',
      eventPhotoPath: 'owner/$petId/event.jpg',
    ));

    expect(created.awardImagePath, contains('award.jpg'));
    expect(created.eventPhotoPath, contains('event.jpg'));
  });

  test('self-reported visit displays the manually entered provider', () {
    final record = VisitRecord.fromJson({
      'id': 'visit-1',
      'pet_id': petId,
      'visit_date': '2026-07-03',
      'provider_name': 'Домашній огляд',
      'reason_for_visit': 'Контроль стану',
      'status': 'self_reported',
    });

    expect(record.clinicName, 'Домашній огляд');
    expect(record.reason, 'Контроль стану');
    expect(record.status, 'self_reported');
  });

  test('medication notification keeps its pet navigation target', () {
    final notification = AppNotification.fromJson({
      'id': 'notification-1',
      'type': 'medication_reminder',
      'title': 'Нагадування про препарат',
      'body': 'Наступна доза',
      'status': 'unread',
      'pet_id': petId,
      'created_at': '2026-07-16T08:00:00Z',
      'data': {
        'pet_name': 'Арчі',
        'medication_id': 'medication-1',
      },
    });

    expect(notification.petId, petId);
    expect(notification.petName, 'Арчі');
    expect(notification.medicationId, 'medication-1');
  });
}
