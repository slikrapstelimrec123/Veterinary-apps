import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/app_scaffold.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  static const confirmation = 'ВИДАЛИТИ';
  final controller = TextEditingController();
  bool isSubmitting = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (controller.text.trim() != confirmation) {
      setState(() => error = 'Введіть слово $confirmation без змін.');
      return;
    }

    setState(() {
      isSubmitting = true;
      error = null;
    });

    try {
      if (!SupabaseConfig.useMockData) {
        final response = await Supabase.instance.client.functions.invoke(
          'delete-my-account',
          body: const <String, dynamic>{},
        );
        if (response.status < 200 || response.status >= 300) {
          throw StateError('ACCOUNT_DELETION_FAILED');
        }
      }

      if (!mounted) return;
      await AuthScope.of(context).logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Акаунт і пов’язані з ним дані видалено.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Не вдалося видалити акаунт. Спробуйте ще раз.';
        });
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = controller.text.trim() == confirmation && !isSubmitting;
    return AppScaffold(
      title: 'Видалення акаунта',
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Акаунт, картки тварин, медичні записи, оголошення та завантажені файли буде видалено одразу й безповоротно. Цю дію неможливо скасувати.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() => error = null),
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Введіть $confirmation',
            errorText: error,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: enabled ? submit : null,
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: const Text('Видалити акаунт і дані'),
        ),
      ],
    );
  }
}
