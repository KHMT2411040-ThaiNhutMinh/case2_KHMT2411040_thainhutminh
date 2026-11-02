import 'dart:async';
import 'package:flutter/material.dart';
import 'task_detail_screen.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../models/task.dart';
import '../../services/task_api_service.dart';
import '../../utils/task_labels.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskApiService _apiService = TaskApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  int _requestId = 0; // bỏ qua kết quả của lần gọi cũ khi người dùng gõ nhanh

  bool _isLoading = true;
  String? _errorMessage;
  List<Task> _tasks = [];

  String? _statusFilter;
  String? _priorityFilter;
  String? _roleFilter;
  String _sort = 'createdAt';

  bool get _hasFilter =>
      _searchCtrl.text.trim().isNotEmpty ||
      _statusFilter != null ||
      _priorityFilter != null ||
      _roleFilter != null;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final id = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _apiService.getTasks(
        q: _searchCtrl.text,
        status: _statusFilter,
        priority: _priorityFilter,
        role: _roleFilter,
        sort: _sort,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token hết hạn hoặc không hợp lệ: quay về đăng nhập
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
        return;
      }
      if (!mounted || id != _requestId) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _errorMessage = 'Có lỗi xảy ra: $e';
        _isLoading = false;
      });
    }
  }

  // Gõ xong khoảng nửa giây mới gọi API, tránh gọi sau mỗi ký tự
  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _loadTasks);
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _statusFilter = null;
      _priorityFilter = null;
      _roleFilter = null;
    });
    _loadTasks();
  }

  Future<void> _addTask() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
    if (created == true && mounted) _loadTasks();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.amber;
    }
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
        ...options.entries.map(
          (e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          // Hàng chip phân loại theo vai trò
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _roleFilter == null,
                    onSelected: (_) {
                      setState(() => _roleFilter = null);
                      _loadTasks();
                    },
                  ),
                ),
                ...roleFilterLabels.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _roleFilter == e.key,
                      onSelected: (_) {
                        setState(() => _roleFilter = e.key);
                        _loadTasks();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên công việc',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                        _loadTasks();
                      },
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _filterDropdown(
                  label: 'Trạng thái',
                  value: _statusFilter,
                  options: statusLabels,
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _loadTasks();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterDropdown(
                  label: 'Ưu tiên',
                  value: _priorityFilter,
                  options: priorityLabels,
                  onChanged: (v) {
                    setState(() => _priorityFilter = v);
                    _loadTasks();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTasks,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_hasFilter
                ? 'Không tìm thấy công việc phù hợp'
                : 'Chưa có công việc nào'),
            if (_hasFilter)
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Xóa bộ lọc'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];

        return Card(
          child: ListTile(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(taskId: task.id),
                ),
              );
              if (!mounted) return;
              _loadTasks();
            },
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty) Text(task.description),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildTag(priorityLabels[task.priority] ?? task.priority,
                        _priorityColor(task.priority)),
                    _buildTag(statusLabels[task.status] ?? task.status,
                        _statusColor(task.status)),
                    if (task.access.role != null)
                      _buildTag(
                          roleLabels[task.access.role] ?? task.access.role!,
                          Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            onSelected: (v) {
              setState(() => _sort = v);
              _loadTasks();
            },
            itemBuilder: (_) => sortLabels.entries
                .map(
                  (e) => CheckedPopupMenuItem<String>(
                    value: e.key,
                    checked: _sort == e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
          ),
          IconButton(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'Thêm công việc',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}