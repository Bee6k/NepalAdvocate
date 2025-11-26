import 'package:flutter/services.dart';

/// Formatter that allows only digits and one decimal point, limiting to 2 decimal places
class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    
    // Allow empty string (for clearing the field)
    if (newText.isEmpty) {
      return newValue;
    }
    
    // Check if the new text matches our pattern (digits and optional decimal)
    // Allow: empty, digits, digits with one decimal point, digits with decimal and up to 2 decimal places
    final regex = RegExp(r'^\d*\.?\d{0,2}$');
    
    if (!regex.hasMatch(newText)) {
      // If it doesn't match, return old value to prevent the change
      return oldValue;
    }
    
    // Additional check: prevent multiple decimal points
    final decimalCount = '.'.allMatches(newText).length;
    if (decimalCount > 1) {
      return oldValue;
    }
    
    return newValue;
  }
}

