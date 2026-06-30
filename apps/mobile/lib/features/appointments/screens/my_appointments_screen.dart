import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/appointment_repository.dart';
import '../models/appointment.dart';
import 'appointment_booking_screen.dart';
import 'appointment_details_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final repository = AppointmentRepository();
  late Future<List<Appointment>> appointmentsFuture = repository.getOwnAppointments();

  void refresh() {
    setState(() => appointmentsFuture = repository.getOwnAppointments());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Appointment>>(
      future: appointmentsFuture,
      builder: (context, snapshot) {
        final appointments = snapshot.data ?? [];

        return AppScaffold(
          title: 'Записи',
          subtitle: 'Відстежуйте запитані, підтверджені та скасовані візити.',
          children: [
            FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppointmentBookingScreen()));
                refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Записатися на прийом'),
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Не вдалося завантажити записи.', onRetry: refresh)
            else if (appointments.isEmpty)
              EmptyState(
                title: 'Записів ще немає',
                message: 'Запишіться на візит із профілю опублікованої клініки.',
                icon: Icons.calendar_month_outlined,
                action: OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppointmentBookingScreen())), child: const Text('Знайти час')),
              )
            else
              ...appointments.map((appointment) => _AppointmentTile(appointment: appointment, onChanged: refresh)),
          ],
        );
      },
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment, required this.onChanged});

  final Appointment appointment;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: Text(appointment.clinicName),
        subtitle: Text('${appointment.petName} - ${appointment.serviceName}\n${appointment.appointmentDate.day}.${appointment.appointmentDate.month}.${appointment.appointmentDate.year} - ${appointment.startTime}'),
        isThreeLine: true,
        trailing: Chip(label: Text(appointment.statusLabel)),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AppointmentDetailsScreen(appointmentId: appointment.id)));
          onChanged();
        },
      ),
    );
  }
}
