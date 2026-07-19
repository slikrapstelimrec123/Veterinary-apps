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
  bool _loading = true;
  bool _processing = false;
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
    try {
      final products = await _purchases.initialize();
      if (mounted) setState(() => _products = products);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      subtitle: 'Кожен пакет діє 30 днів. Оберіть потрібне охоплення.',
      children: [
        _PackageCard(
          title: 'Стандарт',
          price: _product(LappoProducts.listingStandard)?.price ?? '40 грн',
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
  });

  final String title;
  final String price;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;

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
                      child: const Text('Придбати та продовжити'),
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
