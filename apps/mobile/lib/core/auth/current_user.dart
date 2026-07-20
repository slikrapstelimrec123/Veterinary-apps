enum UserRole {
  petOwner,
  unsupported,
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.city,
    this.onboardingCompletedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? city;
  final DateTime? onboardingCompletedAt;

  bool get isPetOwner => role == UserRole.petOwner;
  bool get hasCompletedOnboarding => onboardingCompletedAt != null;

  static UserRole roleFromString(String? value) {
    return switch (value) {
      'pet_owner' || 'platform_admin' => UserRole.petOwner,
      _ => UserRole.unsupported,
    };
  }
}
