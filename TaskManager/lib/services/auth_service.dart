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
}