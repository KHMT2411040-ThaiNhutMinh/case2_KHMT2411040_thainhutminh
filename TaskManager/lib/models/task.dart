class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Pending',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())?.toLocal()
          : null,
    );
  }
}