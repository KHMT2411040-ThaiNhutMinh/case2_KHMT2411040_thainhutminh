int _n(dynamic v) => (v as num?)?.toInt() ?? 0;

class StatusCounts {
  final int total;
  final int todo;
  final int inProgress;
  final int completed;

  const StatusCounts({
    this.total = 0,
    this.todo = 0,
    this.inProgress = 0,
    this.completed = 0,
  });

  factory StatusCounts.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const StatusCounts();
    return StatusCounts(
      total: _n(j['total']),
      todo: _n(j['todo']),
      inProgress: _n(j['in_progress']),
      completed: _n(j['completed']),
    );
  }
}

class AssignmentStats {
  final StatusCounts assigned;
  final StatusCounts primary;
  const AssignmentStats({required this.assigned, required this.primary});

  factory AssignmentStats.fromJson(Map<String, dynamic> j) => AssignmentStats(
        assigned: StatusCounts.fromJson(j['assigned'] as Map<String, dynamic>?),
        primary: StatusCounts.fromJson(j['primary'] as Map<String, dynamic>?),
      );
}

class DeadlineItem {
  final String id;
  final String title;
  final String status;
  final DateTime? dueDate;

  const DeadlineItem({
    required this.id,
    required this.title,
    required this.status,
    this.dueDate,
  });

  factory DeadlineItem.fromJson(Map<String, dynamic> j) => DeadlineItem(
        id: j['_id'].toString(),
        title: j['title'] ?? '',
        status: j['status'] ?? 'todo',
        dueDate: j['dueDate'] == null
            ? null
            : DateTime.tryParse(j['dueDate'].toString())?.toLocal(),
      );
}

class DeadlineStats {
  final int days;
  final int overdueCount;
  final List<DeadlineItem> overdueItems;
  final int dueSoonCount;
  final List<DeadlineItem> dueSoonItems;
  final int noDueDate;

  const DeadlineStats({
    required this.days,
    required this.overdueCount,
    required this.overdueItems,
    required this.dueSoonCount,
    required this.dueSoonItems,
    required this.noDueDate,
  });

  static List<DeadlineItem> _items(dynamic block) {
    final list = (block is Map ? block['items'] : null) as List<dynamic>?;
    return (list ?? [])
        .map((e) => DeadlineItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  factory DeadlineStats.fromJson(Map<String, dynamic> j) {
    final overdue = j['overdue'];
    final soon = j['dueSoon'];
    return DeadlineStats(
      days: _n(j['days']),
      overdueCount: overdue is Map ? _n(overdue['count']) : 0,
      overdueItems: _items(overdue),
      dueSoonCount: soon is Map ? _n(soon['count']) : 0,
      dueSoonItems: _items(soon),
      noDueDate: _n(j['noDueDate']),
    );
  }
}