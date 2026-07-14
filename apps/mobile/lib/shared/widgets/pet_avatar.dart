import 'package:flutter/material.dart';

class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 56,
  });

  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final radius = size / 2.8;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Initials(
              initial: initial, size: size, radius: radius, context: context),
        ),
      );
    }

    return _Initials(
        initial: initial, size: size, radius: radius, context: context);
  }
}

class _Initials extends StatelessWidget {
  const _Initials(
      {required this.initial,
      required this.size,
      required this.radius,
      required this.context});
  final String initial;
  final double size;
  final double radius;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ctx.mounted
            ? Theme.of(ctx).colorScheme.secondary.withValues(alpha: 0.18)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: ctx.mounted ? Theme.of(ctx).colorScheme.primary : Colors.grey,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
