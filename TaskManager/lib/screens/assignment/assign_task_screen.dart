import 'package:flutter/material.dart';
import '../../models/task_extra.dart';
import '../../services/api_client.dart';
import '../../services/task_api_service.dart';
import '../../widgets/user_picker.dart';

class AssignTaskScreen extends StatefulWidget {
  final String taskId;
  const AssignTaskScreen({super.key, required this.taskId});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _service = TaskApiService();
  List<AssigneeInfo> _items = [];
  bool _loading = true;
  String? _error;
  bool _changed = false; // báo cho màn hình trước biết cần tải lại

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getAssignees(widget.taskId);
      if (!mounted) return;
      setState(() => _items = list);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    try {
      await action();
      _changed = true;
      if (!mounted) return;
      _toast(okMessage);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<void> _add() async {
    final picked = await pickUsers(
      context,
      title: 'Giao việc cho',
      excludeIds: _items.map((e) => e.user.id).toSet(),
    );
    if (picked == null || picked.isEmpty) return;
    await _run(
      () => _service.assign(widget.taskId, picked.map((u) => u.id).toList()),
      'Đã giao việc cho ${picked.length} người',
    );
  }

  Future<void> _remove(AssigneeInfo a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy giao việc'),
        content: Text('Hủy giao việc cho ${a.user.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hủy giao')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => _service.unassign(widget.taskId, a.user.id),
        'Đã hủy giao việc');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Giao công việc')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _add,
          icon: const Icon(Icons.person_add),
          label: const Text('Thêm người'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _load, child: const Text('Thử lại')),
                      ],
                    ),
                  )
                : _items.isEmpty
                    ? const Center(child: Text('Chưa giao cho ai'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final a = _items[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text(a.user.initial)),
                            title: Text(a.user.fullName),
                            subtitle: Text(a.user.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: a.isPrimary
                                      ? 'Bỏ phụ trách chính'
                                      : 'Đặt làm phụ trách chính',
                                  icon: Icon(
                                    a.isPrimary ? Icons.star : Icons.star_border,
                                    color: a.isPrimary ? Colors.amber : null,
                                  ),
                                  onPressed: () => _run(
                                    () => _service.setPrimary(
                                        widget.taskId, a.user.id, !a.isPrimary),
                                    a.isPrimary
                                        ? 'Đã bỏ phụ trách chính'
                                        : 'Đã đặt phụ trách chính',
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hủy giao việc',
                                  icon: const Icon(Icons.person_remove),
                                  onPressed: () => _remove(a),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}