import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        _InviteCard(),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Служба підтримки'),
                subtitle: const Text('Написати нам із запитанням або проблемою.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Служба підтримки', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          const Text(
                            'Якщо у вас виникли питання або проблеми — зв\'яжіться з нами зручним способом.',
                            style: TextStyle(color: Color(0xFF707784)),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: const Text('Написати на email'),
                            subtitle: const Text('support@lappo.app'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: const Text('Telegram'),
                            subtitle: const Text('@lappo_support'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

class _InviteCard extends StatelessWidget {
  static const _inviteLink = 'https://lappo.app/invite';

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Запросити друзів', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Поділіться посиланням з іншими власниками тварин — нехай теж тримають медичні картки своїх улюбленців під рукою.',
                style: TextStyle(color: Color(0xFF6270A0)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E4F0)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        _inviteLink,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      tooltip: 'Скопіювати',
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: _inviteLink));
                        Navigator.pop(_);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Посилання скопійовано.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Поділитись'),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: _inviteLink));
                    Navigator.pop(_);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Посилання скопійовано — вставте у будь-який месенджер.')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_add_outlined),
        title: const Text('Запросити друзів'),
        subtitle: const Text('Поділіться Lappo з іншими власниками тварин.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showInviteSheet(context),
      ),
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
