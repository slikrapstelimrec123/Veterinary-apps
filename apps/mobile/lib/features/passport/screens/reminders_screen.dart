import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/pet_passport_repository.dart';
import '../domain/pet_passport_models.dart';

class PetRemindersScreen extends StatefulWidget {
  const PetRemindersScreen({super.key, this.petId, this.petName});

  final String? petId;
  final String? petName;

  @override
  State<PetRemindersScreen> createState() => _PetRemindersScreenState();
}

class _PetRemindersScreenState extends State<PetRemindersScreen> {
  final repository = PetPassportRepository();
  late Future<List<PetReminder>> remindersFuture = repository.getReminders(petId: widget.petId);

  void refresh() {
    setState(() => remindersFuture = repository.getReminders(petId: widget.petId));
  }

  Future<void> completeReminder(String id) async {
    await repository.markReminderCompleted(id);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.petName == null ? 'Нагадування' : 'Нагадування ${widget.petName}',
      subtitle: 'Планові вакцинації, обробки та домашній догляд без зайвого шуму.',
      children: [
        FutureBuilder<List<PetReminder>>(
          future: remindersFuture,
          builder: (context, snapshot) {
            final reminders = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorState(message: 'Не вдалося завантажити нагадування.', onRetry: refresh);
            }
            if (reminders.isEmpty) {
              return const EmptyState(
                title: 'Нагадувань поки немає',
                message: 'Додайте першу планову подію для тварини.',
                icon: Icons.event_available_outlined,
              );
            }

            return Column(
              children: reminders.map((reminder) => _ReminderCard(reminder: reminder, onComplete: completeReminder)).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_alert_outlined),
          label: const Text('Додати нагадування'),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.onComplete});

  final PetReminder reminder;
  final ValueChanged<String> onComplete;

  @override
  Widget build(BuildContext context) {
    final isCompleted = reminder.status == 'completed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isCompleted ? Icons.check_circle : Icons.event_note_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Дата: ${reminder.dueDate.toIso8601String().split('T').first}'),
              if (reminder.repeatRule != null) Text('Повтор: ${reminder.repeatRule}'),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: isCompleted ? null : () => onComplete(reminder.id),
                child: Text(isCompleted ? 'Виконано' : 'Позначити виконаним'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
