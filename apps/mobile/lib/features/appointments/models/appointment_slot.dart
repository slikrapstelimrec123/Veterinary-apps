class AppointmentSlot {
  const AppointmentSlot({
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final String doctorId;
  final DateTime date;
  final String startTime;
  final String endTime;

  String get label => startTime;
}
