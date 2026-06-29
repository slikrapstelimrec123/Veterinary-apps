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
      setState(() => localError = 'Enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      setState(() => localError = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => localError = null);
    await AuthScope.of(context).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AppScaffold(
      title: 'Sign in',
      subtitle: auth.useMockData ? 'Preview mode uses a local pet owner account.' : 'Access your pet health history.',
      children: [
        if (localError != null || auth.errorMessage != null) ...[
          Text(localError ?? auth.errorMessage!, style: const TextStyle(color: Color(0xFF9F1239))),
          const SizedBox(height: 12),
        ],
        TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: auth.isLoading ? null : submit,
          child: Text(auth.isLoading ? 'Signing in...' : 'Continue'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: const Text('Create pet owner account'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
          child: const Text('Forgot password?'),
        ),
      ],
    );
  }
}
