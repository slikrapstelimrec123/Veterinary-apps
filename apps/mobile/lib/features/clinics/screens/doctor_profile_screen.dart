import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_card.dart';
import '../models/doctor.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  static const doctor = Doctor(
    id: 'doctor_1',
    fullName: 'Dr. Anna Kovalenko',
    specialization: 'General veterinary care',
    clinicName: 'North Star Vet Clinic',
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: doctor.fullName,
      subtitle: '${doctor.specialization} • ${doctor.clinicName}',
      children: const [
        PlaceholderCard(
          title: 'Profile',
          body: '8 years of experience. Consultations, vaccination, and preventive care.',
          icon: Icons.badge_outlined,
        ),
        SizedBox(height: 12),
        PlaceholderCard(
          title: 'Nearest availability',
          body: 'Today at 15:30, tomorrow at 11:00.',
          icon: Icons.schedule_outlined,
        ),
      ],
    );
  }
}
