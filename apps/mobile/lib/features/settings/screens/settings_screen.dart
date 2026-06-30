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
      title: 'Налаштування',
      subtitle: user == null ? 'Налаштування акаунта та застосунку.' : '${user.fullName} • ${user.email}',
      children: [
        const PlaceholderCard(
          title: 'Профіль',
          body: 'Owner name, email, role, and account settings.',
          icon: Icons.person_outline,
        ),
        if (user != null) ...[
          const SizedBox(height: 12),
          PlaceholderCard(
            title: 'Акаунт',
            body: '${user.fullName}\n${user.email}\nRole: ${user.role.name}',
            icon: Icons.badge_outlined,
          ),
        ],
        const SizedBox(height: 12),
        PlaceholderCard(
          title: 'Демо-режим',
          body: SupabaseConfig.useMockData ? 'Mock data is enabled for local visual preview.' : 'Connected to Supabase.',
          icon: Icons.visibility_outlined,
        ),
        const SizedBox(height: 12),
        const PlaceholderCard(
          title: 'Приватність',
          body: 'Медичні записи та документи за замовчуванням залишаються приватними.',
          icon: Icons.lock_outline,
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
