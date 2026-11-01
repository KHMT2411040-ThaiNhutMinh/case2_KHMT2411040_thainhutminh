import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/task_api_service.dart';
import '../../utils/task_labels.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _service = TaskApiService();
  Task? _task;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await _service.getTask(widget.taskId);
      if (!mounted) return;
      setState(() => _task = t);
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

  String _date(DateTime? d) => d == null
      ? 'Chưa đặt'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _row(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value.isEmpty ? '—' : value),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết công việc')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(_task!.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                                        _row(Icons.notes, 'Mô tả', _task!.description),
                    _row(Icons.flag, 'Mức ưu tiên',
                        priorityLabels[_task!.priority] ?? _task!.priority),
                    _row(Icons.timelapse, 'Trạng thái',
                        statusLabels[_task!.status] ?? _task!.status),
                    _row(Icons.play_arrow, 'Ngày bắt đầu', _date(_task!.startDate)),
                    _row(Icons.event, 'Hạn hoàn thành', _date(_task!.dueDate)),
                  ],
                ),
    );
  }
}