import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/alarm_model.dart';
import '../models/challenge_model.dart';
import '../models/user_progress.dart';
import 'notification_service.dart';

class StorageService extends ChangeNotifier {
  late Box _alarmsBox;
  late Box _challengesBox;
  late Box _progressBox;

  List<AlarmModel> alarms = [];
  List<ChallengeModel> challenges = [];
  UserProgress userProgress = const UserProgress();

  Map<String, dynamic> _asMap(dynamic v) =>
      Map<String, dynamic>.from(v as Map);

  Future<void> init() async {
    _alarmsBox = await Hive.openBox('alarms');
    _challengesBox = await Hive.openBox('challenges');
    _progressBox = await Hive.openBox('progress');

    alarms = _alarmsBox.values.map((v) => AlarmModel.fromMap(_asMap(v))).toList();
    challenges = _challengesBox.values
        .map((v) => ChallengeModel.fromMap(_asMap(v)))
        .toList();

    final p = _progressBox.get('progress');
    if (p != null) userProgress = UserProgress.fromMap(_asMap(p));

    _sortAlarms();

    // نعيد جدولة التنبيهات المفعّلة كل ما التطبيق يفتح
    for (final a in alarms.where((a) => a.isEnabled)) {
      await NotificationService.instance.schedule(a);
    }
  }

  void _sortAlarms() {
    alarms.sort((a, b) =>
        (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  }

  // ---------- التنبيهات ----------

  Future<void> addAlarm({
    required String title,
    required String category,
    required int hour,
    required int minute,
  }) async {
    final alarm = AlarmModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      hour: hour,
      minute: minute,
      createdAt: DateTime.now(),
    );
    await _alarmsBox.put(alarm.id, alarm.toMap());
    alarms.add(alarm);
    _sortAlarms();
    await NotificationService.instance.schedule(alarm);
    notifyListeners();
  }

  Future<void> toggleAlarm(String id) async {
    final i = alarms.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final updated = alarms[i].copyWith(isEnabled: !alarms[i].isEnabled);
    alarms[i] = updated;
    await _alarmsBox.put(id, updated.toMap());
    if (updated.isEnabled) {
      await NotificationService.instance.schedule(updated);
    } else {
      await NotificationService.instance.cancel(id);
    }
    notifyListeners();
  }

  Future<void> deleteAlarm(String id) async {
    alarms.removeWhere((a) => a.id == id);
    await _alarmsBox.delete(id);
    await NotificationService.instance.cancel(id);
    notifyListeners();
  }

  // ---------- التحديات ----------

  Future<void> addChallenge({
    required String title,
    required int durationDays,
    int pointsPerDay = 10,
  }) async {
    final c = ChallengeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      durationDays: durationDays,
      pointsPerDay: pointsPerDay,
      startDate: DateTime.now(),
    );
    await _challengesBox.put(c.id, c.toMap());
    challenges.add(c);
    notifyListeners();
  }

  /// بيسجّل إنجاز اليوم ويرجّع النقاط اللي اتكسبت (0 لو اتسجل قبل كده).
  Future<int> completeChallengeToday(String id) async {
    final i = challenges.indexWhere((c) => c.id == id);
    if (i < 0) return 0;
    final c = challenges[i];
    if (!c.isActive || c.isCompletedToday) return 0;

    final dates = [...c.completedDates, ChallengeModel.todayKey()];
    final finished = dates.length >= c.durationDays;
    final updated = c.copyWith(completedDates: dates, isActive: !finished);
    challenges[i] = updated;
    await _challengesBox.put(id, updated.toMap());

    // مكافأة إضافية لما تخلّص التحدي كله
    final gained = c.pointsPerDay + (finished ? c.durationDays * 5 : 0);
    userProgress = userProgress.addPoints(gained);
    await _progressBox.put('progress', userProgress.toMap());

    notifyListeners();
    return gained;
  }

  Future<void> deleteChallenge(String id) async {
    challenges.removeWhere((c) => c.id == id);
    await _challengesBox.delete(id);
    notifyListeners();
  }
}