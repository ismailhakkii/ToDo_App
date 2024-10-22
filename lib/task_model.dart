class Task {
  String name;
  String? description;
  DateTime date;
  Duration? duration;
  DateTime? startTime; // Geri sayımın başladığı zaman
  bool isCompleted; // Görev tamamlandı mı

  Task({
    required this.name,
    this.description,
    required this.date,
    this.duration,
    this.startTime,
    this.isCompleted = false, // Varsayılan olarak tamamlanmadı
  });

  // JSON dönüşümleri için fonksiyonlar
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'date': date.toIso8601String(),
        'duration': duration?.inSeconds,
        'startTime': startTime?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  static Task fromJson(Map<String, dynamic> json) => Task(
        name: json['name'] as String,
        description: json['description'] as String?,
        date: DateTime.parse(json['date'] as String),
        duration: json['duration'] != null
            ? Duration(seconds: json['duration'] as int)
            : null,
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'] as String)
            : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}
