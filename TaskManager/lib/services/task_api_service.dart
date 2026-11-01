import '../models/task.dart';
import 'api_client.dart';

class TaskApiService {
    Future<List<Task>> getTasks({
    String? q,
    String? status,
    String? priority,
    String? sort,
  }) async {
    final params = <String, String>{};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (sort != null) params['sort'] = sort;

    final path = Uri(
      path: '/tasks',
      queryParameters: params.isEmpty ? null : params,
    ).toString();

    final list = await ApiClient.requestList(path);
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Task> getTask(String id) async {
    final data = await ApiClient.request('GET', '/tasks/$id', auth: true);
    return Task.fromJson(data);
  }
    Future<void> createTask(Map<String, dynamic> data) async {
    await ApiClient.request('POST', '/tasks', body: data, auth: true);
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    final status = data['status'];
    final info = Map<String, dynamic>.from(data)..remove('status');
    await ApiClient.request('PUT', '/tasks/$id', body: info, auth: true);
    if (status != null) {
      await ApiClient.request('PATCH', '/tasks/$id/status',
          body: {'status': status}, auth: true);
    }
  }

  Future<void> deleteTask(String id) async {
    await ApiClient.request('DELETE', '/tasks/$id', auth: true);
  }
}