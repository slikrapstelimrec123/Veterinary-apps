import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Відновлення пароля',
      subtitle: 'Відновлення пароля буде підключено після перевірки входу та реєстрації.',
      children: [
        TextField(decoration: InputDecoration(labelText: 'Електронна пошта')),
      ],
    );
  }
}

