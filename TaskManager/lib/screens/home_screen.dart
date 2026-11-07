import 'package:flutter/material.dart';
import 'profile/profile_screen.dart';
import 'tasks/task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  int _profileVersion = 0; // tăng lên để tải lại tab Cá nhân mỗi lần mở

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const TaskListScreen(),
          ProfileScreen(key: ValueKey(_profileVersion)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          if (i == 1 && _index != 1) _profileVersion++;
          _index = i;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Công việc'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}