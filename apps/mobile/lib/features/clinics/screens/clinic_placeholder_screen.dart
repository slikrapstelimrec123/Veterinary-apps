import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';

class ClinicPlaceholderScreen extends StatelessWidget {
  const ClinicPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Clinics',
      subtitle: 'Clinic search and appointment booking are planned for the next stage.',
      children: [
        EmptyState(
          title: 'Coming next',
          message: 'Clinic search, clinic profiles, doctor profiles, and booking will be available in the next development stage.',
          icon: Icons.local_hospital_outlined,
        ),
      ],
    );
  }
}

