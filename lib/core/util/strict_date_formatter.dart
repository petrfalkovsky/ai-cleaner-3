import 'package:flutter/services.dart';
class StrictDateTimeFormatter extends TextInputFormatter {
  static final RegExp _nonDigitRegex = RegExp(r'[^0-9]');
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    var oldDigits = oldValue.text.replaceAll(_nonDigitRegex, '');
    var newDigits = newValue.text.replaceAll(_nonDigitRegex, '');
    final addedChars = newDigits.length - oldDigits.length;
    if (addedChars == 1 && newDigits.length == 9) {
      final typedHourTens = int.tryParse(newDigits[8]) ?? 0;
      if (typedHourTens > 2) {
        final oldPrefix = oldDigits;
        final newHour = '0$typedHourTens';
        newDigits = oldPrefix + newHour;
      }
    }
    if (!_isValidPartial(newDigits)) {
      return oldValue;
    }
    final masked = _applyMask(newDigits);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }
  bool _isValidPartial(String digits) {
    if (digits.isNotEmpty) {
      final d0 = int.tryParse(digits[0]);
      if (d0 == null || d0 > 3) return false;
    }
    if (digits.length >= 2) {
      final day = int.tryParse(digits.substring(0, 2)) ?? 0;
      if (day < 1 || day > 31) return false;
    }
    if (digits.length >= 3) {
      final m0 = int.tryParse(digits[2]);
      if (m0 == null || m0 > 1) return false;
    }
    if (digits.length >= 4) {
      final month = int.tryParse(digits.substring(2, 4)) ?? 0;
      if (month < 1 || month > 12) return false;
    }
    if (digits.length >= 8) {
      final year = int.tryParse(digits.substring(4, 8)) ?? 0;
      if (year < 1900 || year > 2100) return false;
    }
    if (digits.length >= 9) {
      final h0 = int.tryParse(digits[8]);
      if (h0 == null || h0 > 2) return false;
    }
    if (digits.length >= 10) {
      final hour = int.tryParse(digits.substring(8, 10)) ?? -1;
      if (hour < 0 || hour > 24) return false;
    }
    if (digits.length >= 11) {
      final hour = (digits.length >= 10)
          ? int.tryParse(digits.substring(8, 10)) ?? -1
          : -1;
      final min0 = int.tryParse(digits[10]) ?? -1;
      if (hour == 24) {
        if (min0 != 0) return false;
      } else {
        if (min0 > 5) return false;
      }
    }
    if (digits.length >= 12) {
      final hour = int.tryParse(digits.substring(8, 10)) ?? -1;
      final minute = int.tryParse(digits.substring(10, 12)) ?? -1;
      if (hour == 24) {
        if (minute != 0) return false;
      } else {
        if (minute < 0 || minute > 59) return false;
      }
    }
    return true;
  }
  String _applyMask(String digits) {
    final buf = StringBuffer();
    if (digits.isNotEmpty) {
      buf.write(digits.substring(0, _min(2, digits.length)));
    }
    if (digits.length >= 3) {
      buf.write('/');
      buf.write(digits.substring(2, _min(4, digits.length)));
    }
    if (digits.length >= 5) {
      buf.write('/');
      buf.write(digits.substring(4, _min(8, digits.length)));
    }
    if (digits.length >= 9) {
      buf.write(' ');
      buf.write(digits.substring(8, _min(10, digits.length)));
    }
    if (digits.length >= 11) {
      buf.write(':');
      buf.write(digits.substring(10, _min(12, digits.length)));
    }
    return buf.toString();
  }
  int _min(int a, int b) => a < b ? a : b;
}