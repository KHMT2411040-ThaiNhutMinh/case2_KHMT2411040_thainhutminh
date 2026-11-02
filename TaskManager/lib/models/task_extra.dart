import '../utils/task_labels.dart';
import 'task.dart';

class AssigneeInfo {
  final UserBrief user;
  final bool isPrimary;
  AssigneeInfo({required this.user, required this.isPrimary});

  factory AssigneeInfo.fromJson(Map<String, dynamic> json) => AssigneeInfo(
        user: UserBrief.fromJson(json['user'] as Map<String, dynamic>),
        isPrimary: json['isPrimary'] == true,
      );
}

class ShareInfo {
  final String id;
  final UserBrief user;
  final String permission;
  ShareInfo({required this.id, required this.user, required this.permission});

  factory ShareInfo.fromJson(Map<String, dynamic> json) => ShareInfo(
        id: json['_id'].toString(),
        user: UserBrief.fromJson(json['user'] as Map<String, dynamic>),
        permission: json['permission'] ?? 'viewer',
      );
}

const _fieldLabels = {
  'title': 'tên',
  'description': 'mô tả',
  'priority': 'mức ưu tiên',
  'startDate': 'ngày bắt đầu',
  'dueDate': 'hạn hoàn thành',
};

class ActivityInfo {
  final String id;
  final String action;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final UserBrief? user;

  ActivityInfo({
    required this.id,
    required this.action,
    required this.details,
    required this.createdAt,
    this.user,
  });

  factory ActivityInfo.fromJson(Map<String, dynamic> json) {
    final u = json['user'];
    return ActivityInfo(
      id: json['_id'].toString(),
      action: json['action'] ?? '',
      details: (json['details'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
      user: u is Map<String, dynamic> ? UserBrief.fromJson(u) : null,
    );
  }

  int _count(dynamic v) => v is List ? v.length : 1;
  String _label(Map<String, String> m, dynamic key) =>
      m[key?.toString()] ?? key?.toString() ?? '';

  String get text {
    final d = details;
    switch (action) {
      case 'task_created':
        return 'đã tạo công việc';
      case 'task_updated':
        final ch = d['changes'];
        if (ch is Map && ch.isNotEmpty) {
          final names = ch.keys.map((k) => _fieldLabels[k] ?? k).join(', ');
          return 'đã sửa $names';
        }
        return 'đã chỉnh sửa công việc';
      case 'status_changed':
        return 'đã đổi trạng thái từ "${_label(statusLabels, d['from'])}" '
            'sang "${_label(statusLabels, d['to'])}"';
      case 'task_assigned':
        return 'đã giao việc cho ${_count(d['userIds'])} người';
      case 'assignee_removed':
        return 'đã hủy giao việc cho một người';
      case 'primary_changed':
        return d['isPrimary'] == true
            ? 'đã chỉ định người phụ trách chính'
            : 'đã bỏ chỉ định người phụ trách chính';
      case 'task_shared':
        return 'đã chia sẻ cho ${_count(d['userIds'])} người '
            '(${_label(permissionLabels, d['permission'])})';
      case 'share_changed':
        return 'đã đổi quyền chia sẻ từ "${_label(permissionLabels, d['from'])}" '
            'sang "${_label(permissionLabels, d['to'])}"';
      case 'share_revoked':
        return 'đã thu hồi quyền chia sẻ của một người';
      default:
        return action;
    }
}
}