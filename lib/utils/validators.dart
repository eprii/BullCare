class Validators {
  Validators._();

  static String? requiredText(
    String? value, {
    String label = 'Data',
    int? maxLength,
  }) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return '$label wajib diisi.';
    if (maxLength != null && text.length > maxLength) {
      return '$label maksimal $maxLength karakter.';
    }
    return null;
  }

  static String? email(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').length < 6) return 'Kata sandi minimal 6 karakter.';
    return null;
  }

  static String? decimal(String? value, {String label = 'Nilai'}) {
    final String text = (value ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return '$label wajib diisi.';
    if (double.tryParse(text) == null) return '$label harus berupa angka.';
    return null;
  }

  static String? positiveDecimal(String? value, {String label = 'Nilai'}) {
    final String? basicError = decimal(value, label: label);
    if (basicError != null) return basicError;

    final double number = double.parse((value ?? '').trim().replaceAll(',', '.'));
    if (number <= 0) return '$label harus lebih dari 0.';
    return null;
  }
}
