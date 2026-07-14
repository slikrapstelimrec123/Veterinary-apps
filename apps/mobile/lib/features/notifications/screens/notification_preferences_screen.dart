import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/notification_repository.dart';
import '../domain/notification_preferences.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final repository = NotificationRepository();
  late Future<NotificationPreferences> future = repository.getPreferences();
  NotificationPreferences? preferences;
  bool isSaving = false;

  void refresh() {
    setState(() => future = repository.getPreferences());
  }

  Future<void> save() async {
    final value = preferences;
    if (value == null) return;

    setState(() => isSaving = true);
    try {
      await repository.savePreferences(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Налаштування сповіщень збережено.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не вдалося зберегти налаштування. Спробуйте ще раз.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NotificationPreferences>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData && preferences == null) {
          preferences = snapshot.data;
        }

        final value = preferences;

        return AppScaffold(
          title: 'Налаштування сповіщень',
          subtitle: 'Керуйте важливими оновленнями у застосунку.',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError || value == null)
              ErrorState(
                  message: 'Не вдалося завантажити налаштування.',
                  onRetry: refresh)
            else ...[
              _SwitchCard(
                title: 'Сповіщення у застосунку',
                subtitle:
                    'Основні оновлення будуть показані в розділі сповіщень.',
                value: value.inAppEnabled,
                onChanged: (next) => setState(
                    () => preferences = value.copyWith(inAppEnabled: next)),
              ),
              _SwitchCard(
                title: 'Нагадування про записи',
                subtitle: 'Нагадування за 24 години та за 2 години до прийому.',
                value: value.appointmentRemindersEnabled,
                onChanged: (next) => setState(() => preferences =
                    value.copyWith(appointmentRemindersEnabled: next)),
              ),
              _SwitchCard(
                title: 'Оновлення лікування',
                subtitle:
                    'Нові записи лікування, документи та рекомендації повторного візиту.',
                value: value.treatmentUpdatesEnabled,
                onChanged: (next) => setState(() => preferences =
                    value.copyWith(treatmentUpdatesEnabled: next)),
              ),
              _SwitchCard(
                title: 'Запити на відгук',
                subtitle:
                    'Нагадування залишити відгук після завершеного прийому.',
                value: value.reviewRequestsEnabled,
                onChanged: (next) => setState(() =>
                    preferences = value.copyWith(reviewRequestsEnabled: next)),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.block_outlined),
                  title: Text('Маркетингові сповіщення вимкнені'),
                  subtitle:
                      Text('Рекламні повідомлення не надсилаються в MVP.'),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: isSaving ? null : save,
                  child: Text(isSaving ? 'Збереження...' : 'Зберегти')),
            ],
          ],
        );
      },
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
