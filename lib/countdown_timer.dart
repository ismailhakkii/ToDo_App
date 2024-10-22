import 'package:flutter/material.dart';
import 'dart:async';
import 'task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CountdownTimer extends StatefulWidget {
  final Task task;
  final VoidCallback onCompleted;

  CountdownTimer({required this.task, required this.onCompleted});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remainingTime = Duration();
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

void _calculateRemainingTime() {
  if (widget.task.startTime == null || widget.task.duration == null) {
    setState(() {
      _isCompleted = true;
    });
    return;
  }

  final now = DateTime.now();
  final endTime = widget.task.startTime!.add(widget.task.duration!);
  _remainingTime = endTime.difference(now);

  if (_remainingTime.isNegative) {
    _remainingTime = Duration(seconds: 0);
    _isCompleted = true;
    _completeTask();
  }
}


  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _calculateRemainingTime();
        if (_isCompleted) {
          timer.cancel();
          widget.onCompleted();
        }
      });
    });
  }

  void _completeTask() async {
    // Görevi tamamlandı olarak işaretle
    final prefs = await SharedPreferences.getInstance();
    final String tasksString = prefs.getString('tasks') ?? '[]';
    final List tasksJson = json.decode(tasksString);

    for (int i = 0; i < tasksJson.length; i++) {
      Task t = Task.fromJson(tasksJson[i]);
      if (t.name == widget.task.name &&
          t.date == widget.task.date &&
          t.description == widget.task.description) {
        t.isCompleted = true;
        tasksJson[i] = t.toJson();
        break;
      }
    }

    prefs.setString('tasks', json.encode(tasksJson));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return Text('Süre doldu!');
    } else {
      return Text('Kalan süre: ${_formatDuration(_remainingTime)}');
    }
  }
}
