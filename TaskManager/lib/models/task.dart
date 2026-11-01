class Task {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime? startDate;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.startDate,
    this.dueDate,
  });

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'todo',
      startDate: _date(json['startDate']),
      dueDate: _date(json['dueDate']),
    );
  }
}