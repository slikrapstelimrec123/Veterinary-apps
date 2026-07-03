import 'package:flutter/material.dart';

import '../../../core/auth/auth_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../notifications/screens/notification_preferences_screen.dart';
import 'edit_profile_screen.dart';
import 'legal_text_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser;

    return AppScaffold(
      title: 'Налаштування',
      subtitle: 'Керування акаунтом та застосунком.',
      showLogo: true,
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(user?.fullName ?? 'Власник тварини', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(user?.email ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Редагувати профіль',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_none_outlined),
            title: const Text('Сповіщення'),
            subtitle: const Text('Нагадування та оновлення.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _SettingsLink(
                icon: Icons.privacy_tip_outlined,
                title: 'Політика конфіденційності',
                screen: LegalTextScreen.privacy(),
              ),
              const Divider(height: 1),
              _SettingsLink(
                icon: Icons.description_outlined,
                title: 'Умови використання',
                screen: LegalTextScreen.terms(),
              ),
              const Divider(height: 1),
              _SettingsLink(
                icon: Icons.download_outlined,
                title: 'Запит на експорт даних',
                screen: LegalTextScreen.placeholder(
                  title: 'Запит на експорт даних',
                  body: 'Автоматичний експорт медичних даних буде реалізовано пізніше. Зверніться до підтримки для ручного запиту.',
                ),
              ),
              const Divider(height: 1),
              _SettingsLink(
                icon: Icons.delete_outline,
                title: 'Видалення акаунта',
                screen: LegalTextScreen.placeholder(
                  title: 'Видалення акаунта',
                  body: 'Для видалення акаунта зверніться до служби підтримки. Медичні записи зберігаються відповідно до законодавства.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: auth.logout,
          child: const Text('Вийти'),
        ),
      ],
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({required this.icon, required this.title, required this.screen});

  final IconData icon;
  final String title;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
    );
  }
}
