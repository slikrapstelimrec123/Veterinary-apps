import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../appointments/screens/appointment_booking_screen.dart';
import '../../reviews/data/review_repository.dart';
import '../../reviews/domain/review.dart';
import '../../reviews/screens/clinic_reviews_screen.dart';
import '../../reviews/widgets/rating_widgets.dart';
import '../data/clinic_repository.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../models/service.dart';
import 'doctor_profile_screen.dart';

class ClinicProfileScreen extends StatefulWidget {
  const ClinicProfileScreen({super.key, required this.clinicId});

  final String clinicId;

  @override
  State<ClinicProfileScreen> createState() => _ClinicProfileScreenState();
}

class _ClinicProfileScreenState extends State<ClinicProfileScreen> {
  final repository = ClinicRepository();
  final reviewRepository = ReviewRepository();
  late Future<_ClinicProfileData> dataFuture = _load();

  Future<_ClinicProfileData> _load() async {
    final clinic = await repository.getClinic(widget.clinicId);
    final doctors = await repository.getClinicDoctors(widget.clinicId);
    final services = await repository.getClinicServices(widget.clinicId);
    final summary = await reviewRepository.getClinicSummary(widget.clinicId);
    final reviews = await reviewRepository.getClinicReviews(widget.clinicId);
    return _ClinicProfileData(clinic: clinic, doctors: doctors, services: services, summary: summary, reviews: reviews.take(3).toList());
  }

  void refresh() {
    setState(() => dataFuture = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ClinicProfileData>(
      future: dataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final clinic = data?.clinic;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppScaffold(title: 'Клініка', children: [Center(child: CircularProgressIndicator())]);
        }

        if (snapshot.hasError) {
          return AppScaffold(title: 'Клініка', children: [ErrorState(message: 'Не вдалося завантажити профіль клініки.', onRetry: refresh)]);
        }

        if (clinic == null) {
          return const AppScaffold(
            title: 'Клініка',
            children: [EmptyState(title: 'Клініка недоступна', message: 'Ця клініка не опублікована або більше не існує.', icon: Icons.local_hospital_outlined)],
          );
        }

        return AppScaffold(
          title: clinic.name,
          subtitle: clinic.locationLabel,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clinic.description ?? 'Опублікована ветеринарна клініка.', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    if (clinic.phone != null) Text(clinic.phone!),
                    if (clinic.email != null) Text(clinic.email!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            RatingSummaryCard(summary: data!.summary, emptyText: 'Відгуків ще немає. Вони з’являться після завершених записів.'),
            if (data.summary.hasReviews) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClinicReviewsScreen(clinicId: clinic.id, clinicName: clinic.name))),
                child: const Text('Переглянути всі відгуки'),
              ),
              ...data.reviews.map((review) => ReviewCard(review: review)),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AppointmentBookingScreen(clinicId: clinic.id))),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Записатися на прийом'),
            ),
            const SizedBox(height: 20),
            Text('Послуги', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if ((data?.services ?? []).isEmpty)
              const EmptyState(title: 'Публічних послуг немає', message: 'Ця клініка ще не опублікувала послуги для запису.')
            else
              ...data!.services.map((service) => _ServiceTile(service: service)),
            const SizedBox(height: 20),
            Text('Лікарі', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if ((data?.doctors ?? []).isEmpty)
              const EmptyState(title: 'Публічних лікарів немає', message: 'У цієї клініки немає публічних лікарів для запису.')
            else
              ...data!.doctors.map((doctor) => _DoctorTile(doctor: doctor)),
          ],
        );
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});

  final ClinicService service;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(service.name),
        subtitle: Text('${service.durationMinutes} хв - ${service.priceLabel}'),
        leading: const Icon(Icons.medical_services_outlined),
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(doctor.fullName),
        subtitle: Text(doctor.specialization),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctorId: doctor.id))),
      ),
    );
  }
}

class _ClinicProfileData {
  const _ClinicProfileData({required this.clinic, required this.doctors, required this.services, required this.summary, required this.reviews});

  final Clinic? clinic;
  final List<Doctor> doctors;
  final List<ClinicService> services;
  final RatingSummary summary;
  final List<Review> reviews;
}
