import 'package:flutter/material.dart';

import '../../../core/auth/auth_state.dart';
import '../../../shared/widgets/app_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _localError = 'Пароль має містити щонайменше 8 символів.');
      return;
    }
    if (password != _confirmationController.text) {
      setState(() => _localError = 'Паролі не збігаються.');
      return;
    }

    setState(() => _localError = null);
    final updated = await AuthScope.of(context).updatePassword(password);
    if (!mounted || !updated) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пароль успішно змінено.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return AppScaffold(
      title: 'Новий пароль',
      subtitle: 'Створіть новий пароль для захисту вашого акаунта.',
      children: [
        if (_localError != null || auth.errorMessage != null) ...[
          Text(
            _localError ?? auth.errorMessage!,
            style: const TextStyle(color: Color(0xFF9F1239)),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Новий пароль'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmationController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Повторіть пароль'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: auth.isLoading ? null : _submit,
          child: Text(auth.isLoading ? 'Збереження...' : 'Змінити пароль'),
        ),
      ],
    );
  }
}
