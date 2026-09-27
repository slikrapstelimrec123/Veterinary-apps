import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../billing/data/billing_repository.dart';
import '../../billing/domain/owner_plan.dart';

/// Shows only the publication balance for the announcement currently being
/// created. The balance is intentionally kept out of the catalogue tabs so it
/// cannot be confused with balances for other announcement types.
class PublicationRemainingCard extends StatefulWidget {
  const PublicationRemainingCard({
    super.key,
    required this.announcementType,
  });

  final String announcementType;

  @override
  State<PublicationRemainingCard> createState() =>
      _PublicationRemainingCardState();
}

class _PublicationRemainingCardState extends State<PublicationRemainingCard> {
  late final Future<PublicationAccess> _accessFuture;

  @override
  void initState() {
    super.initState();
    _accessFuture = BillingRepository().getPublicationAccess(
      widget.announcementType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PublicationAccess>(
      future: _accessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        final access = snapshot.data;
        if (access == null) {
          return _CardContent(
            typeLabel: _typeLabel(widget.announcementType),
            value: 'Не вдалося завантажити',
            icon: Icons.info_outline,
          );
        }

        final remaining = access.remaining;
        return _CardContent(
          typeLabel: _typeLabel(widget.announcementType),
          value: remaining == null
              ? 'Без обмежень'
              : _formatRemaining(remaining),
          icon: remaining == 0
              ? Icons.warning_amber_rounded
              : Icons.confirmation_number_outlined,
          isWarning: remaining == 0,
        );
      },
    );
  }

  static String _typeLabel(String type) => switch (type) {
        'breeding' => 'Пошук партнера',
        'sale' => 'Продаж',
        'event' => 'Подія',
        'service' => 'Послуга',
        'offer' => 'Пропозиція',
        _ => 'Оголошення',
      };

  static String _formatRemaining(int value) {
    final remainder10 = value % 10;
    final remainder100 = value % 100;
    final noun = remainder10 == 1 && remainder100 != 11
        ? 'публікація'
        : remainder10 >= 2 &&
                remainder10 <= 4 &&
                (remainder100 < 12 || remainder100 > 14)
            ? 'публікації'
            : 'публікацій';
    return '$value $noun';
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.typeLabel,
    required this.value,
    required this.icon,
    this.isWarning = false,
  });

  final String typeLabel;
  final String value;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? Colors.orange.shade800 : AppTheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Залишок для «$typeLabel»\n',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
