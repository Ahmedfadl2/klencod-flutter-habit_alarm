import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge_model.dart';
import '../services/storage_service.dart';
import 'add_alarm_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.alarm_add),
              title: const Text('تنبيه جديد'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddAlarmScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('تحدي جديد'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showAddChallengeDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChallengeDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '30');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تحدي جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم التحدي (مثال: هتمرن كل يوم)',
              ),
            ),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد الأيام'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
              if (title.isEmpty || days <= 0) return;
              context
                  .read<StorageService>()
                  .addChallenge(title: title, durationDays: days);
              Navigator.pop(dialogContext);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _challengeTile(
      BuildContext context, StorageService storage, ChallengeModel c) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag),
        title: Text(c.title),
        subtitle: Text('${c.completedDays} / ${c.durationDays} يوم'),
        trailing: c.isCompletedToday
            ? const Icon(Icons.check_circle, color: Colors.green)
            : TextButton(
                onPressed: () async {
                  final gained = await storage.completeChallengeToday(c.id);
                  if (gained > 0 && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('أحسنت! +$gained نقطة')),
                    );
                  }
                },
                child: const Text('أنجزت اليوم'),
              ),
        onLongPress: () => storage.deleteChallenge(c.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final alarms = storage.alarms;
    final progress = storage.userProgress;
    final activeChallenges =
        storage.challenges.where((c) => c.isActive).toList();

    final ratio = progress.pointsToNextLevel == 0
        ? 0.0
        : (progress.currentLevelPoints / progress.pointsToNextLevel)
            .clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('تنبيهاتي')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة المستوى والنقاط
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المستوى ${progress.level}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: ratio, minHeight: 8),
                  const SizedBox(height: 8),
                  Text(
                    '${progress.currentLevelPoints} / ${progress.pointsToNextLevel} نقطة',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // التحديات الجارية
          Text(
            'التحديات الجارية (${activeChallenges.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (activeChallenges.isEmpty)
            const Text('مفيش تحديات دلوقتي، اضغط + عشان تبدأ تحدي')
          else
            ...activeChallenges.map((c) => _challengeTile(context, storage, c)),
          const SizedBox(height: 16),

          // قائمة التنبيهات
          Text('التنبيهات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (alarms.isEmpty)
            const Text('لسه مفيش تنبيهات، اضغط + عشان تضيف')
          else
            ...alarms.map(
              (a) => Card(
                child: ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(a.title),
                  subtitle: Text(
                    '${a.category} • ${TimeOfDay(hour: a.hour, minute: a.minute).format(context)}',
                  ),
                  trailing: Switch(
                    value: a.isEnabled,
                    onChanged: (_) => storage.toggleAlarm(a.id),
                  ),
                  onLongPress: () => storage.deleteAlarm(a.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}