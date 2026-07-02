import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.children,
    this.showLogo = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget> children;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final logoWidget = const _LappoLogo();
    final allActions = [
      if (showLogo) ...[logoWidget, const SizedBox(width: 8)],
      ...?actions,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: allActions.isEmpty ? null : allActions),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (subtitle != null) ...[
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LappoLogo extends StatelessWidget {
  const _LappoLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Text(
              'L',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'Lappo',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMain,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
