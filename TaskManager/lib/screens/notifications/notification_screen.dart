import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();
  List<NotificationItem> _items = [];
  bool _loading = true;
  bool _onlyUnread = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await _service.getAll(unreadOnly: _onlyUnread);
      if (!mounted) return;
      setState(() => _items = list);
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

  Future<void> _open(NotificationItem n) async {
    if (!n.isRead) {
      try {
        await _service.markRead(n.id);
        if (mounted) setState(() => n.isRead = true);
      } on ApiException catch (e) {
        if (mounted) _toast(e.message);
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: n.taskId)),
    );
    if (mounted) _load(silent: true);
  }

  Future<void> _markAll() async {
    try {
      await _service.markAllRead();
      if (!mounted) return;
      _toast('Đã đánh dấu tất cả là đã đọc');
      await _load(silent: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_ind;
      case 'task_shared':
        return Icons.share;
      case 'task_completed':
        return Icons.check_circle;
      case 'due_date_changed':
        return Icons.event;
      case 'due_reminder':
        return Icons.alarm;  
      default:
        return Icons.sync;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'task_completed':
        return Colors.green;
      case 'due_date_changed':
        return Colors.orange;
      case 'due_reminder':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _time(DateTime d) =>
      '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

  Widget _buildBody() {
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
    if (_items.isEmpty) {
      return Center(
        child: Text(_onlyUnread
            ? 'Không có thông báo chưa đọc'
            : 'Chưa có thông báo nào'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final n = _items[i];
          return ListTile(
            tileColor: n.isRead ? null : Colors.blue.withValues(alpha: 0.08),
            leading: CircleAvatar(
              backgroundColor: _color(n.type).withValues(alpha: 0.15),
              child: Icon(_icon(n.type), color: _color(n.type)),
            ),
            title: Text(
              n.title,
              style: TextStyle(
                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text('${n.message}\n${_time(n.createdAt)}'),
            isThreeLine: true,
            trailing: n.isRead
                ? null
                : const Icon(Icons.circle, size: 10, color: Colors.blue),
            onTap: () => _open(n),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả đã đọc',
            icon: const Icon(Icons.done_all),
            onPressed: _markAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: !_onlyUnread,
                  onSelected: (_) {
                    setState(() => _onlyUnread = false);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Chưa đọc'),
                  selected: _onlyUnread,
                  onSelected: (_) {
                    setState(() => _onlyUnread = true);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}