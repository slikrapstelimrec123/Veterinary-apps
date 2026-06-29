import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Welcome',
      subtitle: 'A clean start screen for future session loading.',
      children: [
        Center(child: Icon(Icons.pets, size: 64)),
      ],
    );
  }
}

