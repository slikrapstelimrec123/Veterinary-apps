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
    final message = user.isClinicRole
        ? 'Clinic management is available in the web admin panel.'
        : 'Platform administration is not part of the mobile MVP.';

    return AppScaffold(
      title: 'Вхід виконано',
      subtitle: '${user.fullName} • ${user.email}',
      children: [
        PlaceholderCard(
          title: 'Доступ за роллю',
          body: message,
          icon: Icons.admin_panel_settings_outlined,
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

