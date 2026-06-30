import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Вітаємо',
      subtitle: 'Стартовий екран для майбутнього завантаження сесії.',
      children: [
        Center(child: Icon(Icons.pets, size: 64)),
      ],
    );
  }
}

