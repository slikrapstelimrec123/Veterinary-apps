import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../models/appointment.dart';
import 'my_appointments_screen.dart';

class AppointmentConfirmationScreen extends StatelessWidget {
  const AppointmentConfirmationScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Запит на запис створено',
      subtitle:
          'Клініка підтвердить час візиту. Статус можна відстежувати у ваших записах.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.clinicName,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(appointment.serviceName),
                const SizedBox(height: 8),
                Text(
                    '${appointment.appointmentDate.day}.${appointment.appointmentDate.month}.${appointment.appointmentDate.year} - ${appointment.startTime}-${appointment.endTime}'),
                const SizedBox(height: 8),
                Text(appointment.doctorName ?? 'Лікаря призначить клініка'),
                const SizedBox(height: 8),
                Text('Тварина: ${appointment.petName}'),
                const SizedBox(height: 12),
                Chip(label: Text(appointment.statusLabel)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
          child: const Text('Переглянути мої записи'),
        ),
      ],
    );
  }
}
