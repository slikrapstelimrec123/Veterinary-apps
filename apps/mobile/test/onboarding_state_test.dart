import 'package:flutter_test/flutter_test.dart';
import 'package:vet_care_mobile/core/auth/current_user.dart';

void main() {
  test('new owner requires onboarding until completion is stored', () {
    const newOwner = CurrentUser(
      id: 'owner-1',
      email: 'owner@example.com',
      fullName: 'Owner',
      role: UserRole.petOwner,
    );
    final completedOwner = CurrentUser(
      id: newOwner.id,
      email: newOwner.email,
      fullName: newOwner.fullName,
      role: newOwner.role,
      onboardingCompletedAt: DateTime.utc(2026, 7, 18),
    );

    expect(newOwner.hasCompletedOnboarding, isFalse);
    expect(completedOwner.hasCompletedOnboarding, isTrue);
  });
}
