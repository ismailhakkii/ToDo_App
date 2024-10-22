import 'package:flutter/material.dart';
import 'task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditTaskPage extends StatefulWidget {
  final Task task;

  EditTaskPage({required this.task});

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  String? _taskName;
  String? _taskDescription;
  DateTime? _expectedDate;
  TimeOfDay? _taskDuration;

  @override
  void initState() {
    super.initState();
    _taskName = widget.task.name;
    _taskDescription = widget.task.description;
    _expectedDate = widget.task.date;
    if (widget.task.duration != null) {
      final totalMinutes = widget.task.duration!.inMinutes;
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      _taskDuration = TimeOfDay(hour: hours, minute: minutes);
    }
  }

  // Görevin beklenen tarihini seçme fonksiyonu
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('tr', ''),
    );
    if (picked != null)
      setState(() {
        _expectedDate = picked;
      });
  }

  // Süre seçme fonksiyonu
  Future<void> _selectDuration(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _taskDuration ?? TimeOfDay.now(),
    );
    if (picked != null)
      setState(() {
        _taskDuration = picked;
      });
  }

  // Görevi güncelleme fonksiyonu
  void _updateTask() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Duration? duration;
      if (isToday(_expectedDate) && _taskDuration != null) {
        duration = Duration(
            hours: _taskDuration!.hour, minutes: _taskDuration!.minute);
      }
     // edit_task_page.dart içinde
Task updatedTask = Task(
  name: _taskName ?? '',
  description: _taskDescription,
  date: _expectedDate ?? DateTime.now(),
  duration: duration,
  startTime: widget.task.startTime,
  isCompleted: widget.task.isCompleted,
);


      final prefs = await SharedPreferences.getInstance();
      final String tasksString = prefs.getString('tasks') ?? '[]';
      final List tasksJson = json.decode(tasksString);

      // Mevcut görevi bul ve güncelle
      for (int i = 0; i < tasksJson.length; i++) {
        Task t = Task.fromJson(tasksJson[i]);
        if (t.name == widget.task.name &&
            t.date == widget.task.date &&
            t.description == widget.task.description) {
          tasksJson[i] = updatedTask.toJson();
          break;
        }
      }

      prefs.setString('tasks', json.encode(tasksJson));

      Navigator.pop(context);
    }
  }

  // Görevi silme fonksiyonu
  void _deleteTask() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksString = prefs.getString('tasks') ?? '[]';
    final List tasksJson = json.decode(tasksString);

    // Mevcut görevi bul ve sil
    tasksJson.removeWhere((item) {
      Task t = Task.fromJson(item);
      return t.name == widget.task.name &&
          t.date == widget.task.date &&
          t.description == widget.task.description;
    });

    prefs.setString('tasks', json.encode(tasksJson));

    Navigator.pop(context);
  }

  bool isToday(DateTime? date) {
    if (date == null) return false;
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    bool isTodayTask = _expectedDate != null && isToday(_expectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Görevi Düzenle'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              // Kullanıcıdan onay almak için bir uyarı gösterebiliriz
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Görevi Sil'),
                  content: Text('Bu görevi silmek istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteTask();
                      },
                      child: Text('Sil'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Görev Adı
              TextFormField(
                initialValue: _taskName,
                decoration: InputDecoration(labelText: 'Görev Adı'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen görev adını giriniz';
                  }
                  return null;
                },
                onSaved: (value) {
                  _taskName = value;
                },
              ),
              // Görev Açıklaması
              TextFormField(
                initialValue: _taskDescription,
                decoration: InputDecoration(labelText: 'Görev Açıklaması'),
                onSaved: (value) {
                  _taskDescription = value;
                },
              ),
              // Görevin Beklenen Tarihi
              ListTile(
                title: Text(_expectedDate == null
                    ? 'Görev Tarihi Seçiniz'
                    : 'Tarih: ${_expectedDate!.day}/${_expectedDate!.month}/${_expectedDate!.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              // Eğer görev bugüne aitse süre seçeneği
              if (isTodayTask)
                ListTile(
                  title: Text(_taskDuration == null
                      ? 'Göreve Ayıracağınız Süreyi Seçiniz'
                      : 'Süre: ${_taskDuration!.format(context)}'),
                  trailing: Icon(Icons.access_time),
                  onTap: () => _selectDuration(context),
                ),
              SizedBox(height: 20),
              // Kaydet Butonu
              ElevatedButton(
                onPressed: _updateTask,
                child: Text('Değişiklikleri Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
