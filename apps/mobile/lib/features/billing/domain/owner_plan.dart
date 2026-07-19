enum OwnerPlanCode { free, pro, proPlus }

class OwnerPlan {
  const OwnerPlan({
    required this.code,
    required this.name,
    required this.petLimit,
    required this.breedingMonthlyLimit,
    required this.saleMonthlyLimit,
    this.monthlyPriceMinor,
    this.yearlyPriceMinor,
    this.introMonthlyPriceMinor,
    this.currency = 'UAH',
    this.status = 'active',
    this.billingPeriod,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.introOfferUsed = false,
  });

  final OwnerPlanCode code;
  final String name;
  final int petLimit;
  final int breedingMonthlyLimit;
  final int saleMonthlyLimit;
  final int? monthlyPriceMinor;
  final int? yearlyPriceMinor;
  final int? introMonthlyPriceMinor;
  final String currency;
  final String status;
  final String? billingPeriod;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final bool introOfferUsed;

  bool get isPaid => code != OwnerPlanCode.free;

  factory OwnerPlan.fromJson(Map<String, dynamic> json) {
    return OwnerPlan(
      code: switch (json['code']) {
        'pro' => OwnerPlanCode.pro,
        'pro_plus' => OwnerPlanCode.proPlus,
        _ => OwnerPlanCode.free,
      },
      name: (json['name'] as String?) ?? 'Free',
      petLimit: (json['pet_limit'] as num?)?.toInt() ?? 3,
      breedingMonthlyLimit:
          (json['breeding_monthly_limit'] as num?)?.toInt() ?? 1,
      saleMonthlyLimit: (json['sale_monthly_limit'] as num?)?.toInt() ?? 1,
      monthlyPriceMinor: (json['monthly_price_minor'] as num?)?.toInt(),
      yearlyPriceMinor: (json['yearly_price_minor'] as num?)?.toInt(),
      introMonthlyPriceMinor:
          (json['intro_monthly_price_minor'] as num?)?.toInt(),
      currency: (json['currency'] as String?) ?? 'UAH',
      status: (json['status'] as String?) ?? 'active',
      billingPeriod: json['billing_period'] as String?,
      currentPeriodEnd: DateTime.tryParse(
        (json['current_period_end'] as String?) ?? '',
      ),
      cancelAtPeriodEnd: json['cancel_at_period_end'] == true,
      introOfferUsed: json['intro_offer_used'] == true,
    );
  }

  static const free = OwnerPlan(
    code: OwnerPlanCode.free,
    name: 'Free',
    petLimit: 3,
    breedingMonthlyLimit: 1,
    saleMonthlyLimit: 1,
  );
}

class PublicationAccess {
  const PublicationAccess({
    required this.allowed,
    required this.free,
    required this.requiresPurchase,
    required this.planCode,
    this.remaining,
  });

  final bool allowed;
  final bool free;
  final bool requiresPurchase;
  final String planCode;
  final int? remaining;

  factory PublicationAccess.fromJson(Map<String, dynamic> json) {
    return PublicationAccess(
      allowed: json['allowed'] == true,
      free: json['free'] == true,
      requiresPurchase: json['requires_purchase'] == true,
      planCode: (json['plan'] as String?) ?? 'free',
      remaining: (json['remaining'] as num?)?.toInt(),
    );
  }
}
