class Appointment {
  const Appointment({
    required this.id,
    required this.petName,
    required this.clinicName,
    required this.startsAt,
    required this.status,
  });

  final String id;
  final String petName;
  final String clinicName;
  final DateTime startsAt;
  final String status;
}

