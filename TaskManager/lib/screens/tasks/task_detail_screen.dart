import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/task_extra.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/task_api_service.dart';
import '../../utils/task_labels.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _service = TaskApiService();
  Task? _task;
  List<AssigneeInfo> _assignees = [];
  List<ShareInfo> _shares = [];
  List<ActivityInfo> _activities = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // Các phần phụ lỗi thì để trống, không làm hỏng cả trang
  Future<List<T>> _safe<T>(Future<List<T>> f) async {
    try {
      return await f;
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final t = await _service.getTask(widget.taskId);
      final (assignees, shares, activities) = await (
        _safe(_service.getAssignees(widget.taskId)),
        _safe(_service.getShares(widget.taskId)),
        _safe(_service.getActivities(widget.taskId)),
      ).wait;
      if (!mounted) return;
      setState(() {
        _task = t;
        _assignees = assignees;
        _shares = shares;
        _activities = activities;
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

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: _task)),
    );
    if (changed == true && mounted) {
      _toast('Cập nhật công việc thành công');
      _load();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text('Bạn có chắc muốn xóa "${_task!.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteTask(widget.taskId);
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<void> _changeStatus(String? status) async {
    if (status == null || _task == null || status == _task!.status) return;
    try {
      await _service.changeStatus(widget.taskId, status);
      if (!mounted) return;
      _toast('Đã cập nhật trạng thái');
      await _load(silent: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  String _date(DateTime? d) => d == null
      ? 'Chưa đặt'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _dateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _row(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value.isEmpty ? '—' : value),
      );

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );

  Widget _personTile(UserBrief u, {String? tag}) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: Text(u.initial)),
        title: Text(u.fullName),
        subtitle: Text(u.email),
        trailing: tag == null
            ? null
            : Chip(label: Text(tag), visualDensity: VisualDensity.compact),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      );

  Widget _statusField(Task t) {
    if (!t.access.canChangeStatus) {
      return _row(Icons.timelapse, 'Trạng thái',
          statusLabels[t.status] ?? t.status);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey('status-${t.status}'),
        initialValue: t.status,
        decoration: const InputDecoration(
          labelText: 'Trạng thái',
          prefixIcon: Icon(Icons.timelapse),
          border: OutlineInputBorder(),
        ),
        items: statusLabels.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: _changeStatus,
      ),
    );
  }

  Widget _buildContent(Task t) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Vai trò của bạn: ${roleLabels[t.access.role] ?? 'Không rõ'}',
            style: const TextStyle(color: Colors.blue)),
        const SizedBox(height: 8),
        _row(Icons.notes, 'Mô tả', t.description),
        _row(Icons.flag, 'Mức ưu tiên', priorityLabels[t.priority] ?? t.priority),
        _statusField(t),
        _row(Icons.play_arrow, 'Ngày bắt đầu', _date(t.startDate)),
        _row(Icons.event, 'Hạn hoàn thành', _date(t.dueDate)),
        _section('Người tạo'),
        t.createdByUser == null
            ? _empty('Không rõ')
            : _personTile(t.createdByUser!),
        _section('Người được giao (${_assignees.length})'),
        if (_assignees.isEmpty) _empty('Chưa giao cho ai'),
        ..._assignees.map((a) =>
            _personTile(a.user, tag: a.isPrimary ? 'Phụ trách chính' : null)),
        _section('Người được chia sẻ (${_shares.length})'),
        if (_shares.isEmpty) _empty('Chưa chia sẻ cho ai'),
        ..._shares.map((s) =>
            _personTile(s.user, tag: permissionLabels[s.permission])),
        _section('Lịch sử hoạt động'),
        if (_activities.isEmpty) _empty('Chưa có hoạt động nào'),
        ..._activities.map(
          (a) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, size: 20),
            title: Text('${a.user?.fullName ?? 'Ai đó'} ${a.text}'),
            subtitle: Text(_dateTime(a.createdAt)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _task;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: t == null
            ? null
            : [
                if (t.access.canEditInfo)
                  IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Sửa',
                      onPressed: _edit),
                if (t.access.canDelete)
                  IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Xóa',
                      onPressed: _delete),
              ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || t == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error ?? 'Không tải được dữ liệu'),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _load, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _buildContent(t),
    );
  }
}