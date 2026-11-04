import '../models/notification_item.dart';
import 'api_client.dart';

class NotificationService {
  Future<List<NotificationItem>> getAll({bool unreadOnly = false}) async {
    final path =
        unreadOnly ? '/notifications?unread=true' : '/notifications';
    final list = await ApiClient.requestList(path);
    return list
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final data = await ApiClient.request(
      'GET',
      '/notifications/unread-count',
      auth: true,
    );
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    await ApiClient.request('PATCH', '/notifications/$id/read', auth: true);
  }

  Future<void> markAllRead() async {
    await ApiClient.request('PATCH', '/notifications/read-all', auth: true);
  }
}