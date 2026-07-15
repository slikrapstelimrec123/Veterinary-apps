import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/app_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Введіть коректну електронну пошту');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      if (SupabaseConfig.useMockData) {
        await Future.delayed(const Duration(seconds: 1));
      } else {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          email,
          redirectTo: 'lappo://auth/reset-password',
        );
      }
      if (mounted) {
        setState(() => _sent = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не вдалося надіслати лист. Спробуйте ще раз.');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Відновлення пароля',
      children: _sent
          ? [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_read_outlined,
                          size: 48, color: Color(0xFF4CAF50)),
                      const SizedBox(height: 16),
                      Text('Лист надіслано',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Перевірте пошту ${_emailController.text.trim()} та перейдіть за посиланням для зміни пароля.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF707784)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Повернутись до входу'),
              ),
            ]
          : [
              const Text(
                  'Введіть вашу електронну пошту — ми надішлемо посилання для відновлення пароля.'),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Електронна пошта',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFE35D6A))),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Надіслати посилання'),
              ),
            ],
    );
  }
}
