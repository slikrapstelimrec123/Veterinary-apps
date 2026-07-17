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
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? city;

  bool get isPetOwner => role == UserRole.petOwner;

  static UserRole roleFromString(String? value) {
    return switch (value) {
      'pet_owner' => UserRole.petOwner,
      _ => UserRole.unsupported,
    };
  }
}
