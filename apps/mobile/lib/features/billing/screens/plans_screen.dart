import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/billing_repository.dart';
import '../domain/owner_plan.dart';
import '../services/store_purchase_service.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> with WidgetsBindingObserver {
  final _repository = BillingRepository();
  late final StorePurchaseService _purchases =
      StorePurchaseService(repository: _repository);
  StreamSubscription<StorePurchaseUpdate>? _updates;
  RealtimeChannel? _entitlementChannel;
  Timer? _planRefreshTimer;
  OwnerPlan _current = OwnerPlan.free;
  List<ProductDetails> _products = const [];
  bool _loading = true;
  bool _refreshing = false;
  bool _refreshInFlight = false;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updates = _purchases.updates.listen(_onPurchaseUpdate);
    _load();
    _subscribeToPlanChanges();
    _planRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshPlan(showProgress: false),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updates?.cancel();
    _planRefreshTimer?.cancel();
    final entitlementChannel = _entitlementChannel;
    if (entitlementChannel != null && SupabaseConfig.isConfigured) {
      Supabase.instance.client.removeChannel(entitlementChannel);
    }
    _purchases.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPlan(showProgress: false);
    }
  }

  void _subscribeToPlanChanges() {
    if (SupabaseConfig.useMockData) return;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    _entitlementChannel = client
        .channel('mobile-owner-entitlement-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'owner_entitlements',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _refreshPlan(showProgress: false),
        )
        .subscribe();
  }

  Future<void> _load() async {
    if (_refreshInFlight) return;
    setState(() {
      _refreshInFlight = true;
      _refreshing = true;
      _loading = true;
      _error = null;
    });
    try {
      final initialPlan = await _repository.getCurrentPlan();
      if (!mounted) return;
      setState(() => _current = initialPlan);

      final products = await _purchases.initialize();
      final confirmedPlan = await _repository.getCurrentPlan();
      if (!mounted) return;
      setState(() {
        _current = confirmedPlan;
        _products = products;
      });
      await _repository.track('paywall_viewed');
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Не вдалося завантажити пропозиції магазину.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
          _refreshInFlight = false;
        });
        unawaited(_refreshAfterStartup());
      }
    }
  }

  Future<void> _refreshAfterStartup() async {
    for (final delay in const [
      Duration(milliseconds: 800),
      Duration(seconds: 2),
    ]) {
      await Future<void>.delayed(delay);
      if (!mounted) return;
      await _refreshPlan(showProgress: false);
    }
  }

  Future<OwnerPlan?> _refreshPlan({bool showProgress = true}) async {
    if (_refreshInFlight || !mounted) return null;
    _refreshInFlight = true;
    if (showProgress) {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }
    try {
      final plan = await _repository.getCurrentPlan();
      if (!mounted) return null;
      setState(() {
        _current = plan;
        _error = null;
      });
      return plan;
    } catch (_) {
      if (mounted && showProgress) {
        setState(() {
          _error = 'Не вдалося оновити активний тариф. Спробуйте ще раз.';
        });
      }
      return null;
    } finally {
      _refreshInFlight = false;
      if (mounted && showProgress) setState(() => _refreshing = false);
    }
  }

  Future<void> _refreshAfterPurchase(String? productId) async {
    final expectedPlan = switch (productId) {
      LappoProducts.proMonthly || LappoProducts.proYearly => OwnerPlanCode.pro,
      LappoProducts.proPlusMonthly ||
      LappoProducts.proPlusYearly =>
        OwnerPlanCode.proPlus,
      _ => null,
    };
    const delays = [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];

    for (final delay in delays) {
      if (delay != Duration.zero) await Future<void>.delayed(delay);
      if (!mounted) return;
      final plan = await _refreshPlan(showProgress: false);
      if (plan != null && (expectedPlan == null || plan.code == expectedPlan)) {
        return;
      }
    }
  }

  void _onPurchaseUpdate(StorePurchaseUpdate update) {
    if (!mounted) return;
    if (update.state == StorePurchaseState.pending) {
      setState(() => _processing = true);
      return;
    }
    setState(() => _processing = false);
    if (update.state == StorePurchaseState.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Підписку успішно активовано.')),
      );
      unawaited(_refreshAfterPurchase(update.productId));
    } else if (update.state == StorePurchaseState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(update.message ?? 'Не вдалося виконати покупку.')),
      );
    }
  }

  ProductDetails? _product(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> _buy(String id) async {
    final product = _product(id);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ця пропозиція ще налаштовується в магазині.'),
        ),
      );
      return;
    }
    setState(() => _processing = true);
    try {
      await _repository.track(
        'purchase_started',
        properties: {'product_id': id},
      );
      final started = await _purchases.buy(product);
      if (!started && mounted) setState(() => _processing = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося відкрити оплату.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return AppScaffold(
      title: 'Тарифи Lappo',
      subtitle: 'Оберіть можливості, які відповідають кількості ваших тварин.',
      actions: [
        IconButton(
          tooltip: 'Оновити тариф',
          onPressed: _refreshing ? null : _refreshPlan,
          icon: _refreshing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
      ],
      children: [
        _CurrentPlanCard(plan: _current),
        const SizedBox(height: 16),
        _PlanCard(
          title: 'Free',
          subtitle: 'Для базового ведення медичної картки',
          accent: AppTheme.textSecondary,
          features: const [
            'До 2 тварин',
            'Медичні записи та документи',
            '1 особисте оголошення для в’язки або продажу на місяць',
            'Події безкоштовно',
          ],
          selected: _current.code == OwnerPlanCode.free,
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Pro',
          subtitle: 'Для власника кількох улюбленців',
          accent: AppTheme.primary,
          badge: 'Перший місяць — 39 грн',
          features: const [
            'До 5 тварин',
            '3 оголошення пошуку партнера на місяць',
            '3 оголошення продажу на місяць',
            'Події безкоштовно',
          ],
          selected: _current.code == OwnerPlanCode.pro,
          monthlyLabel:
              _product(LappoProducts.proMonthly)?.price ?? '79 грн/місяць',
          yearlyLabel:
              _product(LappoProducts.proYearly)?.price ?? '799 грн/рік',
          onMonthly: _processing ? null : () => _buy(LappoProducts.proMonthly),
          onYearly: _processing ? null : () => _buy(LappoProducts.proYearly),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Pro+',
          subtitle: 'Для питомників та професійних заводчиків',
          accent: const Color(0xFF3D2A73),
          badge: 'Перший місяць — 249 грн',
          features: const [
            'До 20 тварин',
            '20 оголошень пошуку партнера на місяць',
            '20 оголошень продажу на місяць',
            'Події безкоштовно',
          ],
          selected: _current.code == OwnerPlanCode.proPlus,
          monthlyLabel:
              _product(LappoProducts.proPlusMonthly)?.price ?? '499 грн/місяць',
          yearlyLabel:
              _product(LappoProducts.proPlusYearly)?.price ?? '4 999 грн/рік',
          onMonthly:
              _processing ? null : () => _buy(LappoProducts.proPlusMonthly),
          onYearly:
              _processing ? null : () => _buy(LappoProducts.proPlusYearly),
        ),
        if (_processing) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.danger),
          ),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: _processing ? null : _purchases.restore,
          child: const Text('Відновити покупки'),
        ),
        const Text(
          'Підписка поновлюється автоматично, доки її не скасовано в '
          'налаштуваннях App Store або Google Play. Вступна ціна доступна '
          'один раз для нового підписника.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.plan});

  final OwnerPlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primary.withValues(alpha: 0.1),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Icon(Icons.workspace_premium_outlined, color: Colors.white),
        ),
        title: Text(
          'Ваш тариф — ${plan.name}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(_currentPlanDetails(plan)),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.features,
    required this.selected,
    this.badge,
    this.monthlyLabel,
    this.yearlyLabel,
    this.onMonthly,
    this.onYearly,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<String> features;
  final bool selected;
  final String? badge;
  final String? monthlyLabel;
  final String? yearlyLabel;
  final VoidCallback? onMonthly;
  final VoidCallback? onYearly;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? accent : AppTheme.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ),
                if (selected)
                  const Chip(
                    avatar: Icon(Icons.check, size: 16),
                    label: Text('Активний'),
                  ),
              ],
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (badge != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
            if (monthlyLabel != null && yearlyLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMonthly,
                      child: Text('${monthlyLabel!} / місяць'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onYearly,
                      child: Text('${yearlyLabel!} / рік'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Річна підписка — приблизно 2 місяці безкоштовно',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}

String _currentPlanDetails(OwnerPlan plan) {
  if (plan.unlimited) return 'Безлімітний доступ до всіх можливостей';

  final announcements = plan.breedingMonthlyLimit + plan.saleMonthlyLimit;
  final limits = 'До ${plan.petLimit} тварин · '
      '$announcements особистих оголошень/міс.';
  final periodEnd = plan.currentPeriodEnd;
  if (periodEnd == null) return limits;

  final renewal = plan.cancelAtPeriodEnd ? ' · без автопоновлення' : '';
  return '$limits\nДіє до ${_date(periodEnd)}$renewal';
}
