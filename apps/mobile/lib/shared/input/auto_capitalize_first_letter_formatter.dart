import 'package:flutter/services.dart';

/// Makes the first alphabetic character entered in a text field uppercase.
///
/// This complements [TextCapitalization.sentences]: the latter is a keyboard
/// hint and does not guarantee capitalization when text is pasted or when a
/// physical keyboard is used.
class AutoCapitalizeFirstLetterFormatter extends TextInputFormatter {
  const AutoCapitalizeFirstLetterFormatter();

  static final _letter = RegExp(r'[A-Za-zА-Яа-яІіЇїЄєҐґ]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final match = _letter.firstMatch(newValue.text);
    if (match == null) return newValue;

    final index = match.start;
    final character = newValue.text.substring(index, match.end);
    final upper = character.toUpperCase();
    if (character == upper) return newValue;

    final text = newValue.text.replaceRange(index, match.end, upper);
    final offset = newValue.selection.baseOffset;
    final adjustment = upper.length - character.length;
    final newOffset = offset < 0
        ? offset
        : offset >= match.end
            ? offset + adjustment
            : offset;
    return newValue.copyWith(
      text: text,
      selection: newValue.selection.copyWith(
        baseOffset: newOffset,
        extentOffset: newValue.selection.extentOffset >= match.end
            ? newValue.selection.extentOffset + adjustment
            : newValue.selection.extentOffset,
      ),
    );
  }
}
