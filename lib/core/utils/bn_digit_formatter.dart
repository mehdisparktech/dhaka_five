import 'package:flutter/services.dart';

class BanglaDigitFormatter extends TextInputFormatter {
  static const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  static const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    for (int i = 0; i < bn.length; i++) {
      text = text.replaceAll(bn[i], en[i]);
    }
    return newValue.copyWith(text: text);
  }
}
