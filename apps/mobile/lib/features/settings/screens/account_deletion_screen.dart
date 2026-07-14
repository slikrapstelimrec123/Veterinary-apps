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
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw const AuthException('Authentication required');
        await Supabase.instance.client
            .from('account_deletion_requests')
            .insert({
          'user_id': user.id,
          'status': 'pending',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Запит прийнято. Видалення буде завершено протягом 30 днів.',
          ),
        ),
      );
      await AuthScope.of(context).logout();
    } on PostgrestException catch (exception) {
      if (!mounted) return;
      final alreadyRequested = exception.code == '23505';
      setState(() {
        error = alreadyRequested
            ? 'Запит на видалення вже прийнято.'
            : 'Не вдалося надіслати запит. Спробуйте ще раз.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Не вдалося надіслати запит. Спробуйте ще раз.');
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
              'Після підтвердження ми почнемо видалення акаунта та персональних даних. Процес триває до 30 днів. Медичні записи, які ми зобов’язані зберігати за законом, можуть бути знеособлені та збережені лише на необхідний строк. Дію неможливо скасувати через застосунок.',
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
          label: const Text('Подати запит на видалення'),
        ),
      ],
    );
  }
}
