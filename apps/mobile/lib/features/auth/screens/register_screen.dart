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
      setState(() => localError = 'Введіть повне ім’я.');
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => localError = 'Введіть дійсну адресу електронної пошти.');
      return;
    }

    if (password.length < 8) {
      setState(() => localError = 'Пароль має містити щонайменше 8 символів.');
      return;
    }

    setState(() => localError = null);
    await AuthScope.of(context).registerPetOwner(
      email: email,
      password: password,
      fullName: fullName,
      phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
    );

    if (!mounted) return;
    final auth = AuthScope.of(context);
    if (auth.currentUser != null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (auth.registrationPendingConfirmation) {
      return AppScaffold(
        title: ‘Підтвердьте пошту’,
        children: [
          const Icon(Icons.mark_email_unread_outlined, size: 64, color: Color(0xFF0D1B3E)),
          const SizedBox(height: 16),
          const Text(
            ‘Ми надіслали вам лист з підтвердженням. Перейдіть за посиланням у листі, щоб активувати акаунт.’,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(‘Зрозуміло’),
          ),
        ],
      );
    }

    return AppScaffold(
      title: ‘Створити акаунт’,
      subtitle: ‘Реєстрація створює профіль власника тварини.’,
      children: [
        if (localError != null || auth.errorMessage != null) ...[
          Text(localError ?? auth.errorMessage!, style: const TextStyle(color: Color(0xFF9F1239))),
          const SizedBox(height: 12),
        ],
        TextField(controller: fullNameController, decoration: const InputDecoration(labelText: ‘Повне ім’я’)),
        const SizedBox(height: 12),
        TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: ‘Електронна пошта’)),
        const SizedBox(height: 12),
        TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: ‘Телефон’)),
        const SizedBox(height: 12),
        TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: ‘Пароль’)),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: auth.isLoading ? null : submit,
          child: Text(auth.isLoading ? ‘Створення акаунта...’ : ‘Створити акаунт’),
        ),
      ],
    );
  }
}

