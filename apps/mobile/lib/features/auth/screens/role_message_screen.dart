import 'package:flutter/material.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/auth/current_user.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_card.dart';

class RoleMessageScreen extends StatelessWidget {
  const RoleMessageScreen({super.key, required this.user});

  final CurrentUser user;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AppScaffold(
      title: 'Тип акаунта не підтримується',
      subtitle: '${user.fullName} • ${user.email}',
      children: [
        const PlaceholderCard(
          title: 'Lappo працює для власників тварин',
          body:
              'Цей тип акаунта більше не підтримується. Увійдіть або створіть акаунт власника тварини.',
          icon: Icons.pets_outlined,
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
