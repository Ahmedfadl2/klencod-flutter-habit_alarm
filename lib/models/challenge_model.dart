class ChallengeModel {
  final String id;
  final String title;
  final int durationDays;
  final int pointsPerDay;
  final DateTime startDate;
  final List<String> completedDates; // مثال: 2026-11-05
  final bool isActive;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.durationDays,
    this.pointsPerDay = 10,
    required this.startDate,
    this.completedDates = const [],
    this.isActive = true,
  });

  int get completedDays => completedDates.length;

  bool get isCompletedToday => completedDates.contains(todayKey());

  static String todayKey() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  ChallengeModel copyWith({List<String>? completedDates, bool? isActive}) =>
      ChallengeModel(
        id: id,
        title: title,
        durationDays: durationDays,
        pointsPerDay: pointsPerDay,
        startDate: startDate,
        completedDates: completedDates ?? this.completedDates,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'durationDays': durationDays,
        'pointsPerDay': pointsPerDay,
        'startDate': startDate.toIso8601String(),
        'completedDates': completedDates,
        'isActive': isActive,
      };

  factory ChallengeModel.fromMap(Map<String, dynamic> m) => ChallengeModel(
        id: m['id'] as String,
        title: m['title'] as String,
        durationDays: m['durationDays'] as int,
        pointsPerDay: m['pointsPerDay'] as int,
        startDate: DateTime.parse(m['startDate'] as String),
        completedDates: List<String>.from(m['completedDates'] as List),
        isActive: m['isActive'] as bool,
      );
}