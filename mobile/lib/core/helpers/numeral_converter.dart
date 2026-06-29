import 'package:intl/intl.dart';

extension NumeralConverter on String {
  String toWesternDigits() {
    const Map<String, String> easternToWestern = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };
    String result = this;
    easternToWestern.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}

class NumberFormatter {
  // Always format currencies, counts, etc., to Western digits
  static String formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 2,
    );
    return format.format(amount).toWesternDigits();
  }

  static String formatNumber(num value, {int decimalDigits = 0}) {
    final format = NumberFormat.decimalPattern('en_US');
    if (decimalDigits > 0) {
      format.minimumFractionDigits = decimalDigits;
      format.maximumFractionDigits = decimalDigits;
    }
    return format.format(value).toWesternDigits();
  }

  static String formatDate(DateTime date) {
    final format = DateFormat('yyyy/MM/dd', 'en_US');
    return format.format(date).toWesternDigits();
  }

  static String formatDateTime(DateTime dateTime) {
    final format = DateFormat('yyyy/MM/dd HH:mm', 'en_US');
    return format.format(dateTime).toWesternDigits();
  }
}
