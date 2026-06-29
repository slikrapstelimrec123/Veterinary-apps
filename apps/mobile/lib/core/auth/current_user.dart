enum UserRole {
  petOwner,
  clinicOwner,
  veterinarian,
  clinicManager,
  platformAdmin,
  unknown,
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;

  bool get isPetOwner => role == UserRole.petOwner;
  bool get isClinicRole => role == UserRole.clinicOwner || role == UserRole.veterinarian || role == UserRole.clinicManager;

  static UserRole roleFromString(String? value) {
    return switch (value) {
      'pet_owner' => UserRole.petOwner,
      'clinic_owner' => UserRole.clinicOwner,
      'veterinarian' => UserRole.veterinarian,
      'clinic_manager' => UserRole.clinicManager,
      'platform_admin' => UserRole.platformAdmin,
      _ => UserRole.unknown,
    };
  }
}

