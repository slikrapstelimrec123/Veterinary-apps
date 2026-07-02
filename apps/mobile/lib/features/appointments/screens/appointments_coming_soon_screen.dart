import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class AppointmentsComingSoonScreen extends StatelessWidget {
  const AppointmentsComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Записи на прийом',
      subtitle: 'Онлайн-запис до ветеринара.',
      children: [
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Icon(Icons.calendar_month_outlined, size: 72, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
              const SizedBox(height: 20),
              Text('Незабаром', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              const Text(
                'Онлайн-запис на прийом до ветеринара з\'явиться у наступному оновленні.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Тим часом ви можете:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _FeatureRow(icon: Icons.edit_note_outlined, text: 'Самостійно додавати записи про прийоми у профілі тварини'),
                _FeatureRow(icon: Icons.folder_outlined, text: 'Завантажувати документи та результати аналізів'),
                _FeatureRow(icon: Icons.qr_code_outlined, text: 'Переглядати цифровий паспорт тварини'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
