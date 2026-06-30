import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class LegalTextScreen extends StatelessWidget {
  const LegalTextScreen.privacy({super.key})
      : title = 'Політика конфіденційності',
        body = 'Beta placeholder. Review with legal specialist before public launch.\n\nПлатформа обробляє дані акаунта, інформацію про тварин, записи, медичні записи та документи. Медичні дані доступні лише власнику тварини, відповідній клініці та дозволеним ролям. Автоматичне видалення й експорт даних будуть реалізовані пізніше через безпечний процес підтримки.';

  const LegalTextScreen.terms({super.key})
      : title = 'Умови використання',
        body = 'Beta placeholder. Review with legal specialist before public launch.\n\nПродукт працює в beta-режимі. Платформа не надає ветеринарні діагнози та не замінює консультацію лікаря. Клініки відповідають за медичний контент, який додають до карток тварин.';

  const LegalTextScreen.placeholder({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      subtitle: 'Beta readiness',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(body),
          ),
        ),
      ],
    );
  }
}
