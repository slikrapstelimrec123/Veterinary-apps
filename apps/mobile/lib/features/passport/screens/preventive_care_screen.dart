import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/pet_passport_repository.dart';
import '../domain/pet_passport_models.dart';

class PreventiveCareScreen extends StatefulWidget {
  const PreventiveCareScreen({super.key, this.petId, this.petName});

  final String? petId;
  final String? petName;

  @override
  State<PreventiveCareScreen> createState() => _PreventiveCareScreenState();
}

class _PreventiveCareScreenState extends State<PreventiveCareScreen> {
  final repository = PetPassportRepository();
  late Future<List<PetHealthEvent>> eventsFuture = repository.getHealthEvents(petId: widget.petId);

  void refresh() {
    setState(() => eventsFuture = repository.getHealthEvents(petId: widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.petName == null ? 'Профілактика' : 'Профілактика ${widget.petName}',
      subtitle: 'Вакцинації, обробки, ліки та інші події здоров’я в одному паспорті.',
      children: [
        FutureBuilder<List<PetHealthEvent>>(
          future: eventsFuture,
          builder: (context, snapshot) {
            final events = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorState(message: 'Не вдалося завантажити профілактику.', onRetry: refresh);
            }
            if (events.isEmpty) {
              return const EmptyState(
                title: 'Подій поки немає',
                message: 'Додайте вакцинації, обробки або інші важливі медичні події.',
                icon: Icons.health_and_safety_outlined,
              );
            }

            return Column(
              children: events.map((event) => _HealthEventCard(event: event)).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Додати подію'),
        ),
      ],
    );
  }
}

class _HealthEventCard extends StatelessWidget {
  const _HealthEventCard({required this.event});

  final PetHealthEvent event;

  @override
  Widget build(BuildContext context) {
    final nextDate = event.nextDueDate?.toIso8601String().split('T').first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.verified_outlined),
          title: Text(event.title),
          subtitle: Text([
            'Дата: ${event.dateDone.toIso8601String().split('T').first}',
            if (nextDate != null) 'Наступно: $nextDate',
            if (event.clinicName != null) event.clinicName!,
          ].join('\n')),
        ),
      ),
    );
  }
}
