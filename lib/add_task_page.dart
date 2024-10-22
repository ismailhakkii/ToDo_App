import 'package:flutter/material.dart';
import 'task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddTaskPage extends StatefulWidget {
  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  String? _taskName;
  String? _taskDescription;
  DateTime? _expectedDate;
  TimeOfDay? _taskDuration;

  // Görevin beklenen tarihini seçme fonksiyonu
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null)
      setState(() {
        _expectedDate = picked;
      });
  }

  // Süre seçme fonksiyonu (eğer görev bugüne aitse)
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

  // Görevi kaydetme fonksiyonu
void _saveTask() async {
  if (_formKey.currentState != null && _formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    Duration? duration;
    DateTime? startTime;
    if (isToday(_expectedDate) && _taskDuration != null) {
      duration = Duration(
          hours: _taskDuration!.hour, minutes: _taskDuration!.minute);
      startTime = DateTime.now(); // Geri sayımın başladığı an
    }
// add_task_page.dart içinde
Task newTask = Task(
  name: _taskName ?? '',
  description: _taskDescription,
  date: _expectedDate ?? DateTime.now(),
  duration: duration,
  startTime: startTime,
);


    final prefs = await SharedPreferences.getInstance();
    final String tasksString = prefs.getString('tasks') ?? '[]';
    final List tasksJson = json.decode(tasksString);
    tasksJson.add(newTask.toJson());
    prefs.setString('tasks', json.encode(tasksJson));

    Navigator.pop(context);
  }
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
        title: Text('Görev Ekle'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Görev Adı
              TextFormField(
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
                onPressed: _saveTask,
                child: Text('Görevi Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
