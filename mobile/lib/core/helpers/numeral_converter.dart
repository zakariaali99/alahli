class NumeralConverter {
  static String convert(String input) {
    const Map<String, String> numbers = {
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
    
    String output = input;
    numbers.forEach((key, value) {
      output = output.replaceAll(key, value);
    });
    return output;
  }
}
