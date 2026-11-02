import '../models/task.dart';
import 'api_client.dart';

class UserService {
  // Tìm theo tên hoặc email, tối thiểu 2 ký tự (backend trả tối đa 10 người)
  Future<List<UserBrief>> search(String q) async {
    final path = Uri(path: '/users/search', queryParameters: {'q': q.trim()})
        .toString();
    final list = await ApiClient.requestList(path);
    return list
        .map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}