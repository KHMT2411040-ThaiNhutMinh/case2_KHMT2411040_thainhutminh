class UserBrief {
  final String id;
  final String fullName;
  final String email;

  UserBrief({required this.id, required this.fullName, required this.email});

  factory UserBrief.fromJson(Map<String, dynamic> json) => UserBrief(
        id: json['_id'].toString(),
        fullName: json['fullName'] ?? '',
        email: json['email'] ?? '',
      );

  String get initial =>
      fullName.trim().isEmpty ? '?' : fullName.trim()[0].toUpperCase();
}

// Quyền của người đang đăng nhập trên một công việc (do backend tính)
class TaskAccess {
  final String? role; // owner | editor | assignee | viewer
  final bool canView;
  final bool canEditInfo;
  final bool canChangeStatus;
  final bool canDelete;
  final bool canManage;

  const TaskAccess({
    this.role,
    this.canView = false,
    this.canEditInfo = false,
    this.canChangeStatus = false,
    this.canDelete = false,
    this.canManage = false,
  });

  factory TaskAccess.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TaskAccess();
    return TaskAccess(
      role: json['role'] as String?,
      canView: json['canView'] == true,
      canEditInfo: json['canEditInfo'] == true,
      canChangeStatus: json['canChangeStatus'] == true,
      canDelete: json['canDelete'] == true,
      canManage: json['canManage'] == true,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String createdBy;
  final UserBrief? createdByUser;
  final List<String> assigneeIds;
  final String? primaryAssigneeId;
  final TaskAccess access;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.startDate,
    this.dueDate,
    this.createdBy = '',
    this.createdByUser,
    this.assigneeIds = const [],
    this.primaryAssigneeId,
    this.access = const TaskAccess(),
  });

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory Task.fromJson(Map<String, dynamic> json) {
    final creator = json['createdByUser'];
    return Task(
      id: json['_id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'todo',
      startDate: _date(json['startDate']),
      dueDate: _date(json['dueDate']),
      createdBy: json['createdBy']?.toString() ?? '',
      createdByUser:
          creator is Map<String, dynamic> ? UserBrief.fromJson(creator) : null,
      assigneeIds: (json['assigneeIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      primaryAssigneeId: json['primaryAssigneeId']?.toString(),
      access: TaskAccess.fromJson(json['access'] as Map<String, dynamic>?),
    );
  }
}