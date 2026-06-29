import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Forgot password',
      subtitle: 'Password recovery will be connected after core login and registration are verified.',
      children: [
        TextField(decoration: InputDecoration(labelText: 'Email')),
      ],
    );
  }
}

