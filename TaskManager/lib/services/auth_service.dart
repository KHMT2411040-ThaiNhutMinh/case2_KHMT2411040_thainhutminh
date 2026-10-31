import 'api_client.dart';

class AuthService {
  static Future<void> register(String fullName, String email, String password) async {
    final data = await ApiClient.request('POST', '/auth/register',
        body: {'fullName': fullName, 'email': email, 'password': password});
    await ApiClient.saveToken(data['token']);
  }

  static Future<void> login(String email, String password) async {
    final data = await ApiClient.request('POST', '/auth/login',
        body: {'email': email, 'password': password});
    await ApiClient.saveToken(data['token']);
  }

  static Future<void> logout() => ApiClient.clearToken();

  static Future<bool> isLoggedIn() async => (await ApiClient.getToken()) != null;
    static Future<Map<String, dynamic>> getMe() async {
    final data = await ApiClient.request('GET', '/auth/me', auth: true);
    return data['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile(String fullName) async {
    final data = await ApiClient.request('PUT', '/auth/me',
        body: {'fullName': fullName}, auth: true);
    return data['user'] as Map<String, dynamic>;
  }

  static Future<void> changePassword(String current, String next) async {
    await ApiClient.request('PUT', '/auth/change-password',
        body: {'currentPassword': current, 'newPassword': next}, auth: true);
  }
}