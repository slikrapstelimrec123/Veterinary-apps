import 'package:flutter_test/flutter_test.dart';
import 'package:vet_care_mobile/features/announcements/domain/announcement_filter_options.dart';

void main() {
  test('filter values contain only unique non-empty values', () {
    final values = distinctFilterValues([
      'Київ',
      ' київ ',
      'Львів',
      '',
      null,
    ]);

    expect(values, ['Київ', 'Львів']);
  });
}
