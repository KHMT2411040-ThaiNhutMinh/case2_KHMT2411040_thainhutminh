class Validators {
  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label không được để trống';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email không được để trống';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Email không hợp lệ';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Mật khẩu không được để trống';
    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }
}