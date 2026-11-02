import '../models/task.dart';
import '../models/task_extra.dart';
import 'api_client.dart';

class TaskApiService {
  Future<List<Task>> getTasks({
    String? q,
    String? status,
    String? priority,
    String? role,
    String? sort,
  }) async {
    final params = <String, String>{};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (role != null) params['role'] = role;
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

  // ===== 4 hàm mới =====

  Future<List<AssigneeInfo>> getAssignees(String taskId) async {
    final list = await ApiClient.requestList('/tasks/$taskId/assignees');
    return list
        .map((e) => AssigneeInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShareInfo>> getShares(String taskId) async {
    final list = await ApiClient.requestList('/tasks/$taskId/shares');
    return list
        .map((e) => ShareInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityInfo>> getActivities(String taskId,
      {int limit = 10}) async {
    final list =
        await ApiClient.requestList('/tasks/$taskId/activities?limit=$limit');
    return list
        .map((e) => ActivityInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> changeStatus(String taskId, String status) async {
    await ApiClient.request(
      'PATCH',
      '/tasks/$taskId/status',
      body: {'status': status},
      auth: true,
    );
  }
    // ===== Giao việc =====

  Future<void> assign(String taskId, List<String> userIds) async {
    await ApiClient.request('POST', '/tasks/$taskId/assignees',
        body: {'userIds': userIds}, auth: true);
  }

  Future<void> setPrimary(String taskId, String userId, bool isPrimary) async {
    await ApiClient.request('PATCH', '/tasks/$taskId/assignees/$userId',
        body: {'isPrimary': isPrimary}, auth: true);
  }

  Future<void> unassign(String taskId, String userId) async {
    await ApiClient.request('DELETE', '/tasks/$taskId/assignees/$userId',
        auth: true);
  }

  // ===== Chia sẻ =====

  Future<void> share(
      String taskId, List<String> userIds, String permission) async {
    await ApiClient.request('POST', '/tasks/$taskId/shares',
        body: {'userIds': userIds, 'permission': permission}, auth: true);
  }

  Future<void> changeSharePermission(
      String taskId, String shareId, String permission) async {
    await ApiClient.request('PATCH', '/tasks/$taskId/shares/$shareId',
        body: {'permission': permission}, auth: true);
  }

  Future<void> revokeShare(String taskId, String shareId) async {
    await ApiClient.request('DELETE', '/tasks/$taskId/shares/$shareId',
        auth: true);
  }
}