import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../models/appointment.dart';

class AppointmentBookingScreen extends StatelessWidget {
  const AppointmentBookingScreen({super.key});

  static final appointment = Appointment(
    id: 'appointment_1',
    petName: 'Luna',
    clinicName: 'North Star Vet Clinic',
    startsAt: DateTime.now().add(const Duration(days: 1)),
    status: 'scheduled',
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Book appointment',
      subtitle: 'Placeholder booking flow: pet, clinic, service, doctor, date, time, review.',
      children: [
        const DropdownMenu(label: Text('Pet'), dropdownMenuEntries: [DropdownMenuEntry(value: 'Luna', label: 'Luna')]),
        const SizedBox(height: 12),
        const DropdownMenu(label: Text('Service'), dropdownMenuEntries: [DropdownMenuEntry(value: 'Consultation', label: 'Consultation')]),
        const SizedBox(height: 12),
        const DropdownMenu(label: Text('Doctor'), dropdownMenuEntries: [DropdownMenuEntry(value: 'Dr. Anna', label: 'Dr. Anna Kovalenko')]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: const [
            ChoiceChip(label: Text('10:30'), selected: false),
            ChoiceChip(label: Text('12:00'), selected: false),
            ChoiceChip(label: Text('15:30'), selected: true),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: () {}, child: const Text('Confirm appointment')),
      ],
    );
  }
}

