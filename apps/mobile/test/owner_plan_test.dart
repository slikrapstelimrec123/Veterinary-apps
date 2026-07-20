import 'package:flutter_test/flutter_test.dart';
import 'package:vet_care_mobile/features/billing/domain/owner_plan.dart';

void main() {
  test('parses the server-controlled administrator unlimited flag', () {
    final plan = OwnerPlan.fromJson({
      'code': 'pro_plus',
      'name': 'Адміністратор',
      'pet_limit': -1,
      'breeding_monthly_limit': -1,
      'sale_monthly_limit': -1,
      'unlimited': true,
    });

    expect(plan.code, OwnerPlanCode.proPlus);
    expect(plan.unlimited, isTrue);
    expect(plan.petLimit, -1);
  });

  test('ordinary plans are not unlimited by default', () {
    expect(OwnerPlan.free.unlimited, isFalse);
  });
}
