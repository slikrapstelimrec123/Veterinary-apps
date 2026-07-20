import 'package:flutter_test/flutter_test.dart';
import 'package:vet_care_mobile/features/billing/domain/owner_plan.dart';

void main() {
  group('OwnerPlan', () {
    test('parses Pro+ limits and subscription metadata', () {
      final plan = OwnerPlan.fromJson({
        'code': 'pro_plus',
        'name': 'Pro+',
        'pet_limit': 20,
        'breeding_monthly_limit': 20,
        'sale_monthly_limit': 20,
        'monthly_price_minor': 49900,
        'yearly_price_minor': 499900,
        'intro_monthly_price_minor': 24900,
        'billing_period': 'yearly',
        'current_period_end': '2027-07-19T00:00:00Z',
      });

      expect(plan.code, OwnerPlanCode.proPlus);
      expect(plan.petLimit, 20);
      expect(plan.breedingMonthlyLimit, 20);
      expect(plan.saleMonthlyLimit, 20);
      expect(plan.isPaid, isTrue);
      expect(plan.currentPeriodEnd, DateTime.utc(2027, 7, 19));
    });

    test('falls back to safe Free limits', () {
      final plan = OwnerPlan.fromJson(const {});

      expect(plan.code, OwnerPlanCode.free);
      expect(plan.petLimit, 2);
      expect(plan.breedingMonthlyLimit, 1);
      expect(plan.saleMonthlyLimit, 1);
      expect(plan.isPaid, isFalse);
    });
  });

  test('PublicationAccess parses quota and purchase requirement', () {
    final access = PublicationAccess.fromJson({
      'allowed': false,
      'free': false,
      'requires_purchase': true,
      'plan': 'pro',
      'remaining': 0,
    });

    expect(access.allowed, isFalse);
    expect(access.requiresPurchase, isTrue);
    expect(access.planCode, 'pro');
    expect(access.remaining, 0);
  });
}
