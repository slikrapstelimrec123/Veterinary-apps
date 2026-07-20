import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/billing_repository.dart';
import '../services/store_purchase_service.dart';

class ListingPackagesScreen extends StatefulWidget {
  const ListingPackagesScreen({
    super.key,
    required this.announcementType,
  });

  final String announcementType;

  @override
  State<ListingPackagesScreen> createState() => _ListingPackagesScreenState();
}

class _ListingPackagesScreenState extends State<ListingPackagesScreen> {
  final _repository = BillingRepository();
  late final StorePurchaseService _purchases =
      StorePurchaseService(repository: _repository);
  StreamSubscription<StorePurchaseUpdate>? _updates;
  List<ProductDetails> _products = const [];
  Map<String, List<String>> _availableCredits = const {};
  bool _loading = true;
  bool _processing = false;
  bool _creditsLoaded = false;
  String? _pendingTier;

  @override
  void initState() {
    super.initState();
    _updates = _purchases.updates.listen(_onUpdate);
    _load();
  }

  @override
  void dispose() {
    _updates?.cancel();
    _purchases.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _creditsLoaded = false;
      });
    }

    List<ProductDetails> products = const [];
    Map<String, List<String>> credits = const {};
    try {
      products = await _purchases.initialize();
    } catch (_) {
      // The user can still use an available credit when the store is unavailable.
    }
    try {
      credits = await _repository.getAvailableListingCreditsByTier();
      if (mounted) {
        setState(() {
          _products = products;
          _availableCredits = credits;
          _creditsLoaded = true;
        });
      }
    } catch (_) {
      // Keep purchases hidden until the balance can be checked safely.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _credits(String tier) =>
      _availableCredits[tier] ?? const <String>[];

  void _useAvailableCredit(String tier) {
    final credits = _credits(tier);
    if (credits.isEmpty || _processing) return;
    Navigator.pop(context, credits.first);
  }

  ProductDetails? _product(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> _buy(String productId, String tier) async {
    final product = _product(productId);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пакет ще налаштовується в магазині.')),
      );
      return;
    }
    setState(() {
      _processing = true;
      _pendingTier = tier;
    });
    try {
      await _repository.track(
        'purchase_started',
        properties: {
          'product_id': productId,
          'tier': tier,
          'announcement_type': widget.announcementType,
        },
      );
      if (!await _purchases.buy(product) && mounted) {
        setState(() => _processing = false);
      }
    } catch (_) {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _onUpdate(StorePurchaseUpdate update) async {
    if (!mounted) return;
    if (update.state == StorePurchaseState.pending) {
      setState(() => _processing = true);
      return;
    }
    if (update.state == StorePurchaseState.completed) {
      final creditId =
          await _repository.getAvailableListingCredit(tier: _pendingTier);
      if (!mounted) return;
      setState(() => _processing = false);
      if (creditId != null) Navigator.pop(context, creditId);
      return;
    }
    setState(() => _processing = false);
    if (update.state == StorePurchaseState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(update.message ?? 'Не вдалося оплатити пакет.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AppScaffold(
      title: 'Публікація оголошення',
      subtitle:
          'Спочатку використайте доступну публікацію або придбайте потрібний пакет.',
      children: [
        if (!_creditsLoaded)
          _CreditsLoadError(onRetry: _load)
        else ...[
          if (_availableCredits.values.any((items) => items.isNotEmpty)) ...[
            const _SectionTitle(
              title: 'Доступні публікації',
              subtitle:
                  'Подаровані або придбані пакети можна використати без повторної оплати.',
            ),
            if (_credits('standard').isNotEmpty) ...[
              _PackageCard(
                title: 'Стандарт',
                price: 'Доступно: ${_credits('standard').length}',
                description: 'Звичайна позиція у списку протягом 30 днів.',
                icon: Icons.article_outlined,
                buttonLabel: 'Використати без оплати',
                accent: const Color(0xFF16866D),
                onTap:
                    _processing ? null : () => _useAvailableCredit('standard'),
              ),
              const SizedBox(height: 12),
            ],
            if (_credits('top_7').isNotEmpty) ...[
              _PackageCard(
                title: 'ТОП 7',
                price: 'Доступно: ${_credits('top_7').length}',
                description:
                    '7 днів у ТОП, 3 автоматичні підняття та 30 днів публікації.',
                icon: Icons.trending_up,
                buttonLabel: 'Використати без оплати',
                accent: const Color(0xFF16866D),
                onTap: _processing ? null : () => _useAvailableCredit('top_7'),
              ),
              const SizedBox(height: 12),
            ],
            if (_credits('top_15').isNotEmpty) ...[
              _PackageCard(
                title: 'ТОП 15',
                price: 'Доступно: ${_credits('top_15').length}',
                description:
                    '15 днів у ТОП, 5 автоматичних підняттів та 30 днів публікації.',
                icon: Icons.auto_awesome,
                buttonLabel: 'Використати без оплати',
                accent: const Color(0xFF16866D),
                onTap: _processing ? null : () => _useAvailableCredit('top_15'),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 10),
          ],
          if (_availableCredits.values.any((items) => items.isEmpty)) ...[
            const _SectionTitle(
              title: 'Придбати публікацію',
              subtitle:
                  'Нижче показані лише пакети, яких зараз немає у вашому залишку.',
            ),
            if (_credits('standard').isEmpty) ...[
              _PackageCard(
                title: 'Стандарт',
                price:
                    _product(LappoProducts.listingStandard)?.price ?? '40 грн',
                description: 'Звичайна позиція у списку протягом 30 днів.',
                icon: Icons.article_outlined,
                onTap: _processing
                    ? null
                    : () => _buy(
                          LappoProducts.listingStandard,
                          'standard',
                        ),
              ),
              const SizedBox(height: 12),
            ],
            if (_credits('top_7').isEmpty) ...[
              _PackageCard(
                title: 'ТОП 7',
                price: _product(LappoProducts.listingTop7)?.price ?? '80 грн',
                description:
                    '7 днів у ТОП, 3 автоматичні підняття та 30 днів публікації.',
                icon: Icons.trending_up,
                accent: AppTheme.primary,
                onTap: _processing
                    ? null
                    : () => _buy(LappoProducts.listingTop7, 'top_7'),
              ),
              const SizedBox(height: 12),
            ],
            if (_credits('top_15').isEmpty)
              _PackageCard(
                title: 'ТОП 15',
                price: _product(LappoProducts.listingTop15)?.price ?? '150 грн',
                description:
                    '15 днів у ТОП, 5 автоматичних підняттів та 30 днів публікації.',
                icon: Icons.auto_awesome,
                accent: const Color(0xFF3D2A73),
                onTap: _processing
                    ? null
                    : () => _buy(LappoProducts.listingTop15, 'top_15'),
              ),
          ],
        ],
        if (_processing) ...[
          const SizedBox(height: 18),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.title,
    required this.price,
    required this.description,
    required this.icon,
    required this.onTap,
    this.accent = AppTheme.textMain,
    this.buttonLabel = 'Придбати та продовжити',
  });

  final String title;
  final String price;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.12),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onTap,
                      child: Text(buttonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textMain,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditsLoadError extends StatelessWidget {
  const _CreditsLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(
              Icons.sync_problem_outlined,
              color: AppTheme.danger,
              size: 32,
            ),
            const SizedBox(height: 10),
            const Text(
              'Не вдалося перевірити доступні публікації.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Оновіть дані перед покупкою, щоб не оплачувати пакет повторно.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Оновити'),
            ),
          ],
        ),
      ),
    );
  }
}
