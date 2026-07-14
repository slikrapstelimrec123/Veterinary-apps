class BreedingAnnouncement {
  const BreedingAnnouncement({
    required this.id,
    required this.ownerName,
    required this.phone,
    required this.breed,
    required this.myDogName,
    required this.myDogGender,
    required this.myDogAge,
    this.myDogPhotoUrl,
    this.desiredBreed,
    this.conditions,
    this.notes,
    this.location,
    required this.createdAt,
    this.isActive = true,
    this.ownerId,
  });

  final String id;
  final String ownerName;
  final String phone;
  final String breed;
  final String myDogName;
  final String myDogGender;
  final int myDogAge;
  final String? myDogPhotoUrl;
  final String? desiredBreed;
  final String? conditions;
  final String? notes;
  final String? location;
  final DateTime createdAt;
  final bool isActive;
  final String? ownerId;

  String get genderLabel => myDogGender == 'male' ? 'Самець' : 'Самка';
  String get ageLabel {
    if (myDogAge == 1) return '1 рік';
    if (myDogAge < 5) return '$myDogAge роки';
    return '$myDogAge років';
  }
}
