import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/app_scaffold.dart';

class BetaFeedbackScreen extends StatefulWidget {
  const BetaFeedbackScreen({super.key});

  @override
  State<BetaFeedbackScreen> createState() => _BetaFeedbackScreenState();
}

class _BetaFeedbackScreenState extends State<BetaFeedbackScreen> {
  final messageController = TextEditingController();
  String category = 'bug';
  int? rating;
  bool isSubmitting = false;
  String? error;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final user = AuthScope.of(context).currentUser;
    final message = messageController.text.trim();

    if (message.length < 8) {
      setState(() => error = 'Опишіть відгук трохи детальніше.');
      return;
    }

    setState(() {
      error = null;
      isSubmitting = true;
    });

    try {
      if (!SupabaseConfig.useMockData && user != null) {
        await Supabase.instance.client.from('beta_feedback').insert({
          'user_id': user.id,
          'role': user.role.name,
          'category': category,
          'rating': rating,
          'message': message,
          'status': 'new',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Дякуємо, відгук надіслано beta-команді.')));
      Navigator.of(context).pop();
    } catch (_) {
      setState(() => error = 'Не вдалося надіслати відгук. Спробуйте пізніше.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Beta-відгук',
      subtitle: 'Допоможіть підготувати продукт до тестування в клініках.',
      children: [
        if (error != null) ...[
          Text(error!, style: const TextStyle(color: Color(0xFF9F1239))),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<String>(
          value: category,
          decoration: const InputDecoration(labelText: 'Категорія'),
          items: const [
            DropdownMenuItem(value: 'bug', child: Text('Помилка')),
            DropdownMenuItem(value: 'usability', child: Text('Зручність')),
            DropdownMenuItem(value: 'feature_request', child: Text('Побажання')),
            DropdownMenuItem(value: 'data_issue', child: Text('Проблема з даними')),
            DropdownMenuItem(value: 'other', child: Text('Інше')),
          ],
          onChanged: (value) => setState(() => category = value ?? 'other'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: rating,
          decoration: const InputDecoration(labelText: 'Оцінка beta-досвіду'),
          items: const [
            DropdownMenuItem(value: 5, child: Text('5 - добре')),
            DropdownMenuItem(value: 4, child: Text('4')),
            DropdownMenuItem(value: 3, child: Text('3')),
            DropdownMenuItem(value: 2, child: Text('2')),
            DropdownMenuItem(value: 1, child: Text('1 - критично')),
          ],
          onChanged: (value) => setState(() => rating = value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: messageController,
          minLines: 4,
          maxLines: 7,
          maxLength: 2000,
          decoration: const InputDecoration(labelText: 'Повідомлення', hintText: 'Що сталося або що варто покращити?'),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: isSubmitting ? null : submit, child: Text(isSubmitting ? 'Надсилання...' : 'Надіслати')),
      ],
    );
  }
}
