class AlarmModel {
  final String id;
  final String title;
  final String category;
  final int hour;
  final int minute;
  final bool isEnabled;
  final DateTime createdAt;

  const AlarmModel({
    required this.id,
    required this.title,
    required this.category,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    required this.createdAt,
  });

  AlarmModel copyWith({bool? isEnabled}) => AlarmModel(
        id: id,
        title: title,
        category: category,
        hour: hour,
        minute: minute,
        isEnabled: isEnabled ?? this.isEnabled,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'hour': hour,
        'minute': minute,
        'isEnabled': isEnabled,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AlarmModel.fromMap(Map<String, dynamic> m) => AlarmModel(
        id: m['id'] as String,
        title: m['title'] as String,
        category: m['category'] as String,
        hour: m['hour'] as int,
        minute: m['minute'] as int,
        isEnabled: m['isEnabled'] as bool,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}