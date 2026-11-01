import '../models/task.dart';
import 'api_client.dart';

class TaskApiService {
  Future<List<Task>> getTasks() async {
    final list = await ApiClient.requestList('/tasks');
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }
}