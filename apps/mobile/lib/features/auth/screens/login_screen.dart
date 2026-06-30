import 'package:flutter/material.dart';

import '../../../core/auth/auth_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? localError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!email.contains('@')) {
      setState(() => localError = 'Введіть дійсну адресу електронної пошти.');
      return;
    }

    if (password.length < 6) {
      setState(() => localError = 'Пароль має містити щонайменше 6 символів.');
      return;
    }

    setState(() => localError = null);
    await AuthScope.of(context).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AppScaffold(
      title: 'Увійти',
      subtitle: auth.useMockData ? 'Демо-режим використовує локальний акаунт власника тварини.' : 'Відкрийте історію здоров’я своїх тварин.',
      children: [
        if (localError != null || auth.errorMessage != null) ...[
          Text(localError ?? auth.errorMessage!, style: const TextStyle(color: Color(0xFF9F1239))),
          const SizedBox(height: 12),
        ],
        TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Електронна пошта')),
        const SizedBox(height: 12),
        TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль')),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: auth.isLoading ? null : submit,
          child: Text(auth.isLoading ? 'Вхід...' : 'Продовжити'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: const Text('Створити акаунт власника тварини'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
          child: const Text('Забули пароль?'),
        ),
      ],
    );
  }
}
