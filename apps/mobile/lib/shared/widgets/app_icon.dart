import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 24, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}

// Named constants for type-safe usage
class AppIcons {
  static const paw = 'paw';
  static const calendarPlus = 'calendar_plus';
  static const bell = 'bell';
  static const settings = 'settings';
  static const doctor = 'doctor';
  static const document = 'document';
  static const calendar = 'calendar';
  static const medicine = 'medicine';
  static const qr = 'qr';
  static const invite = 'invite';
  static const shieldLock = 'shield_lock';
  static const terms = 'terms';
  static const export_ = 'export';
  static const trash = 'trash';
  static const edit = 'edit';
  static const check = 'check';
  static const support = 'support';
  static const feeding = 'feeding';
  static const trophy = 'trophy';
  static const home = 'home';
}
