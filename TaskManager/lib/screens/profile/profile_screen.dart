import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final u = await AuthService.getMe();
      if (!mounted) return;
      setState(() => _user = u);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _logout(); // token hết hạn hoặc không hợp lệ
        return;
      }
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _user!['fullName']);
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật họ tên'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Họ tên'),
            validator: (v) => Validators.required(v, 'Họ tên'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final u = await AuthService.updateProfile(ctrl.text.trim());
      if (!mounted) return;
      setState(() => _user = u);
      _toast('Cập nhật thông tin thành công');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                validator: (v) => Validators.required(v, 'Mật khẩu hiện tại'),
              ),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                validator: Validators.password,
              ),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
                validator: (v) =>
                    v != newCtrl.text ? 'Mật khẩu xác nhận không khớp' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Đổi mật khẩu')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService.changePassword(currentCtrl.text, newCtrl.text);
      if (!mounted) return;
      _toast('Đổi mật khẩu thành công');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
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
                    const CircleAvatar(
                        radius: 40, child: Icon(Icons.person, size: 40)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.badge),
                      title: const Text('Họ tên'),
                      subtitle: Text(_user!['fullName'] ?? ''),
                      trailing: IconButton(
                          icon: const Icon(Icons.edit), onPressed: _editName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(_user!['email'] ?? ''),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Đổi mật khẩu'),
                      onTap: _changePassword,
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Đăng xuất'),
                      onTap: _logout,
                    ),
                  ],
                ),
    );
  }
}