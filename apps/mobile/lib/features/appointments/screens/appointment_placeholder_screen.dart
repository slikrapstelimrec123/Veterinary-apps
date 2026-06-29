import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';

class AppointmentPlaceholderScreen extends StatelessWidget {
  const AppointmentPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Book appointment',
      subtitle: 'This flow is intentionally parked for the next stage.',
      children: [
        EmptyState(
          title: 'Coming next',
          message: 'Appointment booking will be available in the next stage.',
          icon: Icons.calendar_month_outlined,
          action: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
        ),
      ],
    );
  }
}

