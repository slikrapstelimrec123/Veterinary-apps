import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet_care_mobile/shared/input/auto_capitalize_first_letter_formatter.dart';

void main() {
  const formatter = AutoCapitalizeFirstLetterFormatter();

  test('capitalizes the first alphabetic character', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: 'прогулянка',
        selection: TextSelection.collapsed(offset: 10),
      ),
    );

    expect(result.text, 'Прогулянка');
    expect(result.selection.baseOffset, 10);
  });

  test('keeps leading whitespace and upper-case text', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '  Уже правильно',
        selection: TextSelection.collapsed(offset: 15),
      ),
    );

    expect(result.text, '  Уже правильно');
  });
}
