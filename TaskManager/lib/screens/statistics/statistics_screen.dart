import 'package:flutter/material.dart';
import '../../models/statistics.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/statistics_service.dart';
import '../../utils/task_labels.dart';
import '../tasks/task_detail_screen.dart';

/// Trang thống kê đầy đủ (có thanh tiêu đề)
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: const StatisticsBody(),
    );
  }
}

/// Phần nội dung thống kê, có thể nhúng vào màn hình khác (ví dụ tab Cá nhân)
class StatisticsBody extends StatefulWidget {
  const StatisticsBody({super.key});

  @override
  State<StatisticsBody> createState() => _StatisticsBodyState();
}

class _StatisticsBodyState extends State<StatisticsBody> {
  final _service = StatisticsService();
  StatusCounts _tasks = const StatusCounts();
  AssignmentStats? _assign;
  DeadlineStats? _deadline;
  bool _loading = true;
  String? _error;

  static const _todoColor = Colors.grey;
  static const _progressColor = Colors.orange;
  static const _doneColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final tasks = await _service.tasks();
      final assign = await _service.assignments();
      final deadline = await _service.deadlines();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _assign = assign;
        _deadline = deadline;
        _error = null;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
        return;
      }
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _date(DateTime? d) =>
      d == null ? '—' : '${_two(d.day)}/${_two(d.month)}/${d.year}';

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, int count, int total, Color color) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdown(StatusCounts c) {
    return Column(
      children: [
        _statusRow(statusLabels['todo'] ?? 'Chưa thực hiện', c.todo, c.total,
            _todoColor),
        _statusRow(statusLabels['in_progress'] ?? 'Đang thực hiện',
            c.inProgress, c.total, _progressColor),
        _statusRow(statusLabels['completed'] ?? 'Hoàn thành', c.completed,
            c.total, _doneColor),
      ],
    );
  }

  Widget _bigNumber(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _assignBlock(String label, StatusCounts c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${c.total} việc',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '${statusLabels['todo']} ${c.todo}  ·  '
            '${statusLabels['in_progress']} ${c.inProgress}  ·  '
            '${statusLabels['completed']} ${c.completed}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _openTask(String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: id)),
    );
    if (mounted) _load(silent: true);
  }

  List<Widget> _dueList(String title, Color color, List<DeadlineItem> items) {
    if (items.isEmpty) return [];
    return [
      const SizedBox(height: 12),
      Text(title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ...items.map(
        (t) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(t.title),
          subtitle: Text('Hạn: ${_date(t.dueDate)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openTask(t.id),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final a = _assign;
    final d = _deadline;

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          _card('Công việc theo trạng thái', Icons.pie_chart_outline, [
            Text('Tổng cộng: ${_tasks.total} việc',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _breakdown(_tasks),
          ]),
          if (a != null)
            _card('Giao việc', Icons.assignment_ind_outlined, [
              _assignBlock('Được giao cho tôi', a.assigned),
              _assignBlock('Tôi phụ trách chính', a.primary),
            ]),
          if (d != null)
            _card('Hạn hoàn thành', Icons.event_outlined, [
              Row(
                children: [
                  _bigNumber('Quá hạn', d.overdueCount, Colors.red),
                  const SizedBox(width: 8),
                  _bigNumber(
                      'Sắp đến hạn\n(${d.days} ngày)', d.dueSoonCount, Colors.orange),
                  const SizedBox(width: 8),
                  _bigNumber('Chưa đặt hạn', d.noDueDate, Colors.grey),
                ],
              ),
              ..._dueList('Việc quá hạn', Colors.red, d.overdueItems),
              ..._dueList('Việc sắp đến hạn', Colors.orange, d.dueSoonItems),
            ]),
        ],
      ),
    );
  }
}