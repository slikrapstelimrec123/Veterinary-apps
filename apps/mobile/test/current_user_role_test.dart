import 'package:flutter_test/flutter_test.dart';
import 'package:vet_care_mobile/core/auth/current_user.dart';

void main() {
  test('pet owners are supported in the mobile app', () {
    expect(CurrentUser.roleFromString('pet_owner'), UserRole.petOwner);
  });

  test('platform admins can also use the owner mobile experience', () {
    expect(CurrentUser.roleFromString('platform_admin'), UserRole.petOwner);
  });

  test('legacy clinic roles remain unsupported', () {
    expect(CurrentUser.roleFromString('clinic_owner'), UserRole.unsupported);
  });
}
