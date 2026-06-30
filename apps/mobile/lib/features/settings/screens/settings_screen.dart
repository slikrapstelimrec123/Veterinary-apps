import 'package:flutter/material.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/config/supabase_config.dart';
import '../../notifications/screens/notification_preferences_screen.dart';
import 'beta_feedback_screen.dart';
import 'legal_text_screen.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser;

    return AppScaffold(
      title: 'Налаштування',
      subtitle: user == null ? 'Налаштування акаунта та застосунку.' : '${user.fullName} • ${user.email}',
      children: [
        const PlaceholderCard(
          title: 'Профіль',
          body: 'Ім’я, email, роль і налаштування акаунта.',
          icon: Icons.person_outline,
        ),
        if (user != null) ...[
          const SizedBox(height: 12),
          PlaceholderCard(
            title: 'Акаунт',
            body: '${user.fullName}\n${user.email}\nРоль: ${user.role.name}',
            icon: Icons.badge_outlined,
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_none_outlined),
            title: const Text('Сповіщення'),
            subtitle: const Text('Нагадування, оновлення лікування та запити на відгук.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Beta-відгук'),
            subtitle: const Text('Повідомити про помилку, ідею або проблему з даними.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BetaFeedbackScreen())),
          ),
        ),
        const SizedBox(height: 12),
        PlaceholderCard(
          title: 'Демо-режим',
          body: SupabaseConfig.useMockData ? 'Демо-дані увімкнено для локального перегляду.' : 'Підключено до Supabase.',
          icon: Icons.visibility_outlined,
        ),
        const SizedBox(height: 12),
        const PlaceholderCard(
          title: 'Приватність',
          body: 'Медичні записи та документи за замовчуванням залишаються приватними.',
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 12),
        _SettingsLink(
          icon: Icons.privacy_tip_outlined,
          title: 'Політика конфіденційності',
          subtitle: 'Beta placeholder для перевірки з юристом.',
          screen: LegalTextScreen.privacy(),
        ),
        const SizedBox(height: 12),
        _SettingsLink(
          icon: Icons.description_outlined,
          title: 'Умови використання',
          subtitle: 'Beta-умови без фінальної юридичної сили.',
          screen: LegalTextScreen.terms(),
        ),
        const SizedBox(height: 12),
        const _SettingsLink(
          icon: Icons.download_outlined,
          title: 'Запит на експорт даних',
          subtitle: 'Автоматичний експорт буде реалізовано пізніше.',
          screen: LegalTextScreen.placeholder(
            title: 'Запит на експорт даних',
            body: 'Для beta-тесту це безпечний placeholder. Автоматичний експорт даних буде реалізовано після узгодження правил доступу до медичної історії.',
          ),
        ),
        const SizedBox(height: 12),
        const _SettingsLink(
          icon: Icons.delete_outline,
          title: 'Запит на видалення акаунта',
          subtitle: 'Медичні дані не видаляються автоматично.',
          screen: LegalTextScreen.placeholder(
            title: 'Запит на видалення акаунта',
            body: 'Для beta-тесту це безпечний placeholder. Видалення акаунта потребує окремого процесу, щоб не втратити медичні записи клініки та історію лікування.',
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
  const _SettingsLink({required this.icon, required this.title, required this.subtitle, required this.screen});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
