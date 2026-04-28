extension FluxDecimalFormat on num {
  /// Format with max/min decimal digits.
  String formatPrice({int maxDigits = 2, int minDigits = 2}) {
    final str = toStringAsFixed(maxDigits);
    if (minDigits >= maxDigits) return str;
    // Trim trailing zeros but keep at least minDigits
    final dotIndex = str.indexOf('.');
    if (dotIndex == -1) return str;
    var end = str.length;
    while (end > dotIndex + minDigits + 1 && str[end - 1] == '0') {
      end--;
    }
    if (end == dotIndex + 1) return str.substring(0, dotIndex);
    return str.substring(0, end);
  }

  /// Fixed fraction digits formatting.
  String formatFixed(int fractionDigits) {
    return toStringAsFixed(fractionDigits);
  }

  /// Format as percentage string.
  String toPercent({int fractionDigits = 2}) {
    return '${(this * 100).toStringAsFixed(fractionDigits)}%';
  }
}

extension FluxStringDecimal on String {
  FluxDecimalHelper toDecimal() => FluxDecimalHelper(this);
}

class FluxDecimalHelper {
  FluxDecimalHelper(this._value);
  final String _value;

  String format({int maxDigits = 2, int minDigits = 2}) {
    final n = double.tryParse(_value) ?? 0;
    return n.formatPrice(maxDigits: maxDigits, minDigits: minDigits);
  }

  String formatFixed({int fractionDigits = 2}) {
    final n = double.tryParse(_value) ?? 0;
    return n.formatFixed(fractionDigits);
  }

  String toPercent({int fractionDigits = 2}) {
    final n = double.tryParse(_value) ?? 0;
    return n.toPercent(fractionDigits: fractionDigits);
  }
}
