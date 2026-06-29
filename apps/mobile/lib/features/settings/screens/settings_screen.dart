import 'package:flutter/material.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser;

    return AppScaffold(
      title: 'Settings',
      subtitle: user == null ? 'Account and app settings.' : '${user.fullName} • ${user.email}',
      children: [
        const PlaceholderCard(
          title: 'Profile',
          body: 'Owner name, email, role, and account settings.',
          icon: Icons.person_outline,
        ),
        if (user != null) ...[
          const SizedBox(height: 12),
          PlaceholderCard(
            title: 'Account',
            body: '${user.fullName}\n${user.email}\nRole: ${user.role.name}',
            icon: Icons.badge_outlined,
          ),
        ],
        const SizedBox(height: 12),
        PlaceholderCard(
          title: 'Preview mode',
          body: SupabaseConfig.useMockData ? 'Mock data is enabled for local visual preview.' : 'Connected to Supabase.',
          icon: Icons.visibility_outlined,
        ),
        const SizedBox(height: 12),
        const PlaceholderCard(
          title: 'Privacy',
          body: 'Medical records and documents remain private by default.',
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: auth.logout,
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
