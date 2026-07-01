class PhoneValidator {
  static final _libyanRegex = RegExp(r'^09[1-5]\d{7}$');

  static String? validateLibyanPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    final cleaned = value.trim();
    if (!_libyanRegex.hasMatch(cleaned)) {
      return 'رقم هاتف ليبي غير صالح. يجب أن يبدأ بـ 091-095 ويتكون من 10 أرقام';
    }
    return null;
  }
}
