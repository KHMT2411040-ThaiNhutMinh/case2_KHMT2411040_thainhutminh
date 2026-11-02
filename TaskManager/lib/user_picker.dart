import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_client.dart';
import '../services/user_service.dart';

/// Mở hộp thoại tìm và chọn nhiều người. Trả về danh sách đã chọn (hoặc null nếu hủy).
/// [excludeIds]: những người đã có sẵn, không hiện trong kết quả.
Future<List<UserBrief>?> pickUsers(
  BuildContext context, {
  Set<String> excludeIds = const {},
  String title = 'Chọn người',
}) {
  return showDialog<List<UserBrief>>(
    context: context,
    builder: (_) => _UserPickerDialog(excludeIds: excludeIds, title: title),
  );
}

class _UserPickerDialog extends StatefulWidget {
  final Set<String> excludeIds;
  final String title;
  const _UserPickerDialog({required this.excludeIds, required this.title});

  @override
  State<_UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends State<_UserPickerDialog> {
  final _service = UserService();
  final _ctrl = TextEditingController();
  Timer? _debounce;
  int _reqId = 0;

  List<UserBrief> _results = [];
  final Map<String, UserBrief> _selected = {};
  bool _loading = false;
  String? _message = 'Nhập tên hoặc email (ít nhất 2 ký tự)';

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        _results = [];
        _message = 'Nhập tên hoặc email (ít nhất 2 ký tự)';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text));
  }

  Future<void> _search(String text) async {
    final id = ++_reqId;
    setState(() => _loading = true);
    try {
      final users = await _service.search(text);
      if (!mounted || id != _reqId) return;
      final filtered =
          users.where((u) => !widget.excludeIds.contains(u.id)).toList();
      setState(() {
        _results = filtered;
        _message = filtered.isEmpty ? 'Không tìm thấy người dùng phù hợp' : null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _reqId) return;
      setState(() {
        _results = [];
        _message = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _selected.values
                    .map((u) => InputChip(
                          label: Text(u.fullName),
                          onDeleted: () =>
                              setState(() => _selected.remove(u.id)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )
                  : _message != null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_message!, textAlign: TextAlign.center),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: _results.map((u) {
                            final checked = _selected.containsKey(u.id);
                            return CheckboxListTile(
                              dense: true,
                              value: checked,
                              title: Text(u.fullName),
                              subtitle: Text(u.email),
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selected[u.id] = u;
                                } else {
                                  _selected.remove(u.id);
                                }
                              }),
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.values.toList()),
          child: Text('Chọn (${_selected.length})'),
        ),
      ],
    );
  }
}