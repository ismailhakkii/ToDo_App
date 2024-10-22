// lib/home_page.dart

import 'package:flutter/material.dart';
import 'add_task_page.dart';
import 'edit_task_page.dart'; // Yeni eklenen ithalat
import 'task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'countdown_timer.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Task> _todayTasks = [];
  List<Task> _otherTasks = [];

  // Görevleri yükleme fonksiyonu
  void _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksString = prefs.getString('tasks') ?? '[]';
    final List tasksJson = json.decode(tasksString);
    final List<Task> allTasks =
        tasksJson.map((json) => Task.fromJson(json)).toList();

    _todayTasks.clear();
    _otherTasks.clear();

    final today = DateTime.now();

    for (var task in allTasks) {
      if (isSameDate(task.date, today)) {
        _todayTasks.add(task);
      } else if (task.date.isBefore(today)) {
        // Tarihi geçmiş görevleri 'Bugünkü Görevler'e ekleyin
        _todayTasks.add(task);
      } else {
        _otherTasks.add(task);
      }
    }

    setState(() {});
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Görev ekleme sonrası listeyi güncelleme
  void _refreshTasks() {
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Görevler'),
      ),
      body: _buildTaskLists(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskPage()),
          );
          _refreshTasks();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskLists() {
    if (_todayTasks.isEmpty && _otherTasks.isEmpty) {
      return Center(
        child: Text('Bir görev eklemeyi düşünür müsünüz?'),
      );
    } else {
      return ListView(
        children: [
          if (_todayTasks.isNotEmpty)
            _buildTaskSection('Bugünkü Görevler', _todayTasks),
          if (_todayTasks.isEmpty)
            ListTile(
              title: Text('Bugün için hiçbir göreviniz yok.'),
            ),
          if (_otherTasks.isNotEmpty)
            _buildTaskSection('Diğer Görevler', _otherTasks),
        ],
      );
    }
  }

  Widget _buildTaskSection(String title, List<Task> tasks) {
  return ExpansionTile(
    initiallyExpanded: true,
    title: Text(title),
    children: tasks.map((task) {
      return ListTile(
        title: Text(task.name),
        subtitle: _buildTaskSubtitle(task),
        onTap: () async {
          // Görev düzenleme sayfasına geçiş
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditTaskPage(task: task),
            ),
          );
          _refreshTasks(); // Görevler güncellendiğinde listeyi yenile
        },
      );
    }).toList(),
  );
}

Widget _buildTaskSubtitle(Task task) {
  if (task.startTime != null && task.duration != null && !task.isCompleted) {
    return CountdownTimer(task: task, onCompleted: _refreshTasks);
  } else {
    return Text(task.description ??
        'Tarih: ${task.date.day}/${task.date.month}/${task.date.year}');
  }
}

}
