import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class ReviewSuccessScreen extends StatelessWidget {
  const ReviewSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Дякуємо за відгук',
      subtitle: 'Ваш відгук допомагає іншим власникам тварин обирати надійну допомогу.',
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text('Відгук опубліковано в демо-MVP одразу. У наступному етапі можна додати повну модерацію платформи.'),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Готово')),
      ],
    );
  }
}
