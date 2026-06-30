import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../appointments/screens/appointment_booking_screen.dart';
import '../data/clinic_repository.dart';
import '../models/doctor.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final repository = ClinicRepository();
  late Future<Doctor?> doctorFuture = repository.getDoctor(widget.doctorId);

  void refresh() {
    setState(() => doctorFuture = repository.getDoctor(widget.doctorId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Doctor?>(
      future: doctorFuture,
      builder: (context, snapshot) {
        final doctor = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppScaffold(title: 'Лікар', children: [Center(child: CircularProgressIndicator())]);
        }

        if (snapshot.hasError) {
          return AppScaffold(title: 'Лікар', children: [ErrorState(message: 'Не вдалося завантажити профіль лікаря.', onRetry: refresh)]);
        }

        if (doctor == null) {
          return const AppScaffold(
            title: 'Лікар',
            children: [EmptyState(title: 'Лікар недоступний', message: 'Цей лікар недоступний для публічного запису.', icon: Icons.person_off_outlined)],
          );
        }

        return AppScaffold(
          title: doctor.fullName,
          subtitle: '${doctor.specialization} - ${doctor.clinicName}',
          children: [
            _DoctorSummaryCard(doctor: doctor),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Доступність'),
                subtitle: const Text('Оберіть дату й послугу, щоб побачити вільний час.'),
                trailing: FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AppointmentBookingScreen(clinicId: doctor.clinicId, doctorId: doctor.id))),
                  child: const Text('Записатися'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DoctorSummaryCard extends StatelessWidget {
  const _DoctorSummaryCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person_outline)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.specialization, style: Theme.of(context).textTheme.titleMedium),
                      if (doctor.experienceYears != null) Text('Досвід: ${doctor.experienceYears} р.'),
                    ],
                  ),
                ),
              ],
            ),
            if (doctor.bio != null) ...[
              const SizedBox(height: 16),
              Text(doctor.bio!),
            ],
          ],
        ),
      ),
    );
  }
}
