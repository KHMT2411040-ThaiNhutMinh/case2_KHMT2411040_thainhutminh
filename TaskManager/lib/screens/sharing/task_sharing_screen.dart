import 'package:flutter/material.dart';
import '../../models/task_extra.dart';
import '../../services/api_client.dart';
import '../../services/task_api_service.dart';
import '../../utils/task_labels.dart';
import '../../widgets/user_picker.dart';

class TaskSharingScreen extends StatefulWidget {
  final String taskId;
  const TaskSharingScreen({super.key, required this.taskId});

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  final _service = TaskApiService();
  List<ShareInfo> _items = [];
  bool _loading = true;
  String? _error;
  bool _changed = false;

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
      final list = await _service.getShares(widget.taskId);
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

  // Hỏi quyền viewer/editor, trả về null nếu hủy
  Future<String?> _askPermission({String? current}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn quyền'),
        children: permissionLabels.entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, e.key),
                  child: Row(
                    children: [
                      Icon(current == e.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off),
                      const SizedBox(width: 12),
                      Text(e.value),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _add() async {
    final picked = await pickUsers(
      context,
      title: 'Chia sẻ cho',
      excludeIds: _items.map((e) => e.user.id).toSet(),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    final permission = await _askPermission();
    if (permission == null) return;
    await _run(
      () => _service.share(
          widget.taskId, picked.map((u) => u.id).toList(), permission),
      'Đã chia sẻ cho ${picked.length} người',
    );
  }

  Future<void> _change(ShareInfo s) async {
    final permission = await _askPermission(current: s.permission);
    if (permission == null || permission == s.permission) return;
    await _run(
      () => _service.changeSharePermission(widget.taskId, s.id, permission),
      'Đã đổi quyền',
    );
  }

  Future<void> _revoke(ShareInfo s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi quyền'),
        content: Text('Thu hồi quyền truy cập của ${s.user.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Thu hồi')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => _service.revokeShare(widget.taskId, s.id),
        'Đã thu hồi quyền');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Chia sẻ công việc')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _add,
          icon: const Icon(Icons.share),
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
                    ? const Center(child: Text('Chưa chia sẻ cho ai'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = _items[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text(s.user.initial)),
                            title: Text(s.user.fullName),
                            subtitle: Text(
                                '${s.user.email}\nQuyền: ${permissionLabels[s.permission] ?? s.permission}'),
                            isThreeLine: true,
                            onTap: () => _change(s),
                            trailing: IconButton(
                              tooltip: 'Thu hồi quyền',
                              icon: const Icon(Icons.person_remove),
                              onPressed: () => _revoke(s),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}