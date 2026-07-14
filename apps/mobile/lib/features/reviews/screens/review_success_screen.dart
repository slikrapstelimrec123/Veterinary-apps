import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';

class ReviewSuccessScreen extends StatelessWidget {
  const ReviewSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Дякуємо за відгук',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 56, color: AppTheme.success),
                const SizedBox(height: 16),
                Text('Відгук опубліковано',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Ваш відгук допомагає іншим власникам тварин обирати надійну допомогу.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Готово')),
      ],
    );
  }
}
