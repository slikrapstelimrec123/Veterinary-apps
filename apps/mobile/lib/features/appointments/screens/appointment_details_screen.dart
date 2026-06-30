import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../visit_records/data/visit_record_repository.dart';
import '../../visit_records/screens/visit_record_details_screen.dart';
import '../data/appointment_repository.dart';
import '../models/appointment.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final repository = AppointmentRepository();
  final visitRecordRepository = VisitRecordRepository();
  late Future<Appointment?> appointmentFuture = repository.getAppointment(widget.appointmentId);

  void refresh() {
    setState(() => appointmentFuture = repository.getAppointment(widget.appointmentId));
  }

  Future<void> cancel(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скасувати запис?'),
        content: const Text('Клініка побачить, що ви скасували цей запис.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Залишити')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Скасувати запис')),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await repository.cancelOwnerAppointment(appointment, reason: 'Скасовано власником тварини');
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Appointment?>(
      future: appointmentFuture,
      builder: (context, snapshot) {
        final appointment = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppScaffold(title: 'Запис', children: [Center(child: CircularProgressIndicator())]);
        }

        if (snapshot.hasError) {
          return AppScaffold(title: 'Запис', children: [ErrorState(message: 'Не вдалося завантажити запис.', onRetry: refresh)]);
        }

        if (appointment == null) {
          return const AppScaffold(title: 'Запис', children: [EmptyState(title: 'Запис недоступний', message: 'Цей запис недоступний.', icon: Icons.event_busy_outlined)]);
        }

        return AppScaffold(
          title: appointment.clinicName,
          subtitle: appointment.statusLabel,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.serviceName, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text('Тварина: ${appointment.petName}'),
                    Text('Лікар: ${appointment.doctorName ?? 'Призначить клініка'}'),
                    Text('Дата: ${appointment.appointmentDate.day}.${appointment.appointmentDate.month}.${appointment.appointmentDate.year}'),
                    Text('Час: ${appointment.startTime}-${appointment.endTime}'),
                    if (appointment.ownerNote != null) ...[
                      const SizedBox(height: 10),
                      Text('Ваша нотатка: ${appointment.ownerNote}'),
                    ],
                    if (appointment.clinicNote != null) ...[
                      const SizedBox(height: 10),
                      Text('Нотатка клініки: ${appointment.clinicNote}'),
                    ],
                    if (appointment.cancellationReason != null) ...[
                      const SizedBox(height: 10),
                      Text('Причина скасування: ${appointment.cancellationReason}'),
                    ],
                  ],
                ),
              ),
            ),
            FutureBuilder(
              future: visitRecordRepository.getVisitRecordForAppointment(appointment.id),
              builder: (context, recordSnapshot) {
                final record = recordSnapshot.data;
                if (record == null) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitRecordDetailsScreen(recordId: record.id))),
                    icon: const Icon(Icons.medical_information_outlined),
                    label: const Text('Переглянути запис лікування'),
                  ),
                );
              },
            ),
            if (appointment.canOwnerCancel) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => cancel(appointment),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Скасувати запис'),
              ),
            ],
          ],
        );
      },
    );
  }
}
