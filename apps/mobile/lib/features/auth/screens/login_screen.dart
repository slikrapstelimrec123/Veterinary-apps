import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';
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
        if (!auth.useMockData) ...[
          const SizedBox(height: 8),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('або', style: TextStyle(color: AppTheme.textSecondary))),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 8),
          _SocialButton(
            label: 'Увійти через Google',
            icon: _GoogleIcon(),
            onPressed: auth.isLoading ? null : () => auth.signInWithGoogle(),
          ),
          if (defaultTargetPlatform == TargetPlatform.iOS) ...[
            const SizedBox(height: 10),
            _SocialButton(
              label: 'Увійти через Apple',
              icon: const Icon(Icons.apple, size: 20),
              onPressed: auth.isLoading ? null : () => auth.signInWithApple(),
            ),
          ],
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppTheme.border),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        children: [
          Center(
            child: Text('G', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
          ),
        ],
      ),
    );
  }
}
