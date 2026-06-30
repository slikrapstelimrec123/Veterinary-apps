import 'package:flutter/material.dart';

import '../../../core/auth/auth_state.dart';
import '../../../shared/widgets/app_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  String? localError;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (fullName.length < 2) {
      setState(() => localError = 'Enter your full name.');
      return;
    }

    if (!email.contains('@')) {
      setState(() => localError = 'Enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      setState(() => localError = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => localError = null);
    await AuthScope.of(context).registerPetOwner(
      email: email,
      password: password,
      fullName: fullName,
      phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
    );

    if (mounted && AuthScope.of(context).currentUser != null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AppScaffold(
      title: 'Створити акаунт',
      subtitle: 'Реєстрація власника тварини створює профіль pet_owner.',
      children: [
        if (localError != null || auth.errorMessage != null) ...[
          Text(localError ?? auth.errorMessage!, style: const TextStyle(color: Color(0xFF9F1239))),
          const SizedBox(height: 12),
        ],
        TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Повне ім’я')),
        const SizedBox(height: 12),
        TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Електронна пошта')),
        const SizedBox(height: 12),
        TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Телефон')),
        const SizedBox(height: 12),
        TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль')),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: auth.isLoading ? null : submit,
          child: Text(auth.isLoading ? 'Створення акаунта...' : 'Створити акаунт'),
        ),
      ],
    );
  }
}

