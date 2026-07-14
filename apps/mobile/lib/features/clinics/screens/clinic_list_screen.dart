import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/clinic_repository.dart';
import '../models/clinic.dart';
import 'clinic_profile_screen.dart';

class ClinicListScreen extends StatefulWidget {
  const ClinicListScreen({super.key});

  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  final repository = ClinicRepository();
  final searchController = TextEditingController();
  late Future<List<Clinic>> clinicsFuture = repository.getPublishedClinics();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void search() {
    setState(() => clinicsFuture =
        repository.getPublishedClinics(query: searchController.text));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Clinic>>(
      future: clinicsFuture,
      builder: (context, snapshot) {
        final clinics = snapshot.data ?? [];

        return AppScaffold(
          title: 'Клініки',
          subtitle:
              'Оберіть опубліковану клініку, перегляньте послуги й лікарів та запишіть тварину на візит.',
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Пошук клініки або міста',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward), onPressed: search),
              ),
              onSubmitted: (_) => search(),
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити клініки.', onRetry: search)
            else if (clinics.isEmpty)
              const EmptyState(
                  title: 'Клініки не знайдено',
                  message: 'Спробуйте інше місто або назву клініки.',
                  icon: Icons.local_hospital_outlined)
            else
              ...clinics.map((clinic) => _ClinicCard(clinic: clinic)),
          ],
        );
      },
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({required this.clinic});

  final Clinic clinic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.local_hospital_outlined),
          ),
          title: Text(clinic.name),
          subtitle: Text(clinic.locationLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ClinicProfileScreen(clinicId: clinic.id))),
        ),
      ),
    );
  }
}
