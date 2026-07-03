import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class ClinicComingSoonScreen extends StatelessWidget {
  const ClinicComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Клініки',
      subtitle: 'Пошук ветеринарних клінік.',
      children: [
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Icon(Icons.local_hospital_outlined, size: 72, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
              const SizedBox(height: 20),
              Text('Незабаром', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              const Text(
                'Пошук ветеринарних клінік та онлайн-запис на прийом з\'являться у наступному оновленні.',
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
                Text('Що буде доступно:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _FeatureRow(icon: Icons.search_outlined, text: 'Пошук клінік поруч з вами'),
                _FeatureRow(icon: Icons.calendar_today_outlined, text: 'Онлайн-запис на прийом'),
                _FeatureRow(icon: Icons.star_outline, text: 'Відгуки та рейтинги'),
                _FeatureRow(icon: Icons.notifications_none_outlined, text: 'Нагадування про прийом'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Icon(Icons.calendar_month_outlined, size: 56, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text('Записи на прийом', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Онлайн-запис на прийом до ветеринара з\'явиться у наступному оновленні.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
