import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskMasterApp());
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'منبه العادات والتحديات',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF38BDF8),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int totalPoints = 0;
  List> reminders = [];
  List> challenges = [];

  final List> categories = [
    {'name': 'صلاة الفجر', 'icon': Icons.mosque, 'color': 0xFF10B981},
    {'name': 'تمرين رياضي', 'icon': Icons.fitness_center, 'color': 0xFFF59E0B},
    {'name': 'مذاكرة', 'icon': Icons.school, 'color': 0xFF3B82F6},
    {'name': 'قراءة قرآن', 'icon': Icons.menu_book, 'color': 0xFF14B8A6},
    {'name': 'سماع بودكاست', 'icon': Icons.podcasts, 'color': 0xFF8B5CF6},
    {'name': 'حضور موعد', 'icon': Icons.people, 'color': 0xFFEC4899},
    {'name': 'تناول الأدوية', 'icon': Icons.medication, 'color': 0xFFEF4444},
    {'name': 'قراءة كتاب', 'icon': Icons.auto_stories, 'color': 0xFF6366F1},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalPoints = prefs.getInt('points') ?? 0;
      final remString = prefs.getString('reminders');
      final chalString = prefs.getString('challenges');
      if (remString != null) {
        reminders = List>.from(json.decode(remString));
      }
      if (chalString != null) {
        challenges = List>.from(json.decode(chalString));
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('points', totalPoints);
    await prefs.setString('reminders', json.encode(reminders));
    await prefs.setString('challenges', json.encode(challenges));
  }

  void _addPoints(int pts, String message) {
    HapticFeedback.mediumImpact();
    setState(() {
      totalPoints += pts;
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text(
          '$message (+$pts نقطة! 🎉)',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final cat = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => categories[0],
    );
    return cat['icon'] as IconData;
  }

  Color _getCategoryColor(String categoryName) {
    final cat = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => categories[0],
    );
    return Color(cat['color'] as int);
  }

  void _showAddReminderSheet() {
    String selectedCategory = categories[0]['name'] as String;
    TimeOfDay selectedTime = TimeOfDay.now();
    final TextEditingController noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  top: 24,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إضافة تنبيه جديد ⏰',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('اختر نوع التنبيه:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final String catName = cat['name'] as String;
                        final int catColorInt = cat['color'] as int;
                        final IconData catIconData = cat['icon'] as IconData;
                        final bool isSelected = selectedCategory == catName;
                        return ChoiceChip(
                          label: Text(catName),
                          avatar: Icon(
                            catIconData,
                            size: 18,
                            color: isSelected ? Colors.white : Color(catColorInt),
                          ),
                          selected: isSelected,
                          selectedColor: Color(catColorInt),
                          onSelected: (_) {
                            setModalState(() => selectedCategory = catName);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'ملاحظة إضافية (اختياري)',
                        hintText: 'مثال: سورة الكهف، دواء الفيتامين، موعد...',
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      tileColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: const Icon(Icons.access_time, color: Color(0xFF38BDF8)),
                      title: const Text('وقت التنبيه'),
                      trailing: Text(
                        selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            reminders.add({
                              'category': selectedCategory,
                              'note': noteController.text.trim(),
                              'time': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              'active': true,
                            });
                          });
                          _saveData();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'حفظ التنبيه',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddChallengeSheet() {
    String selectedCategory = categories[1]['name'] as String;
    TimeOfDay selectedTime = TimeOfDay.now();
    int durationDays = 7;
    final TextEditingController titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  top: 24,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إنشاء هدف أو تحدي جديد 🏆',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'اسم التحدي',
                        hintText: 'مثال: تمرين يومي، صلاة الفجر، قراءة...',
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('الفئة:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final String catName = cat['name'] as String;
                        final int catColorInt = cat['color'] as int;
                        final bool isSelected = selectedCategory == catName;
                        return ChoiceChip(
                          label: Text(catName),
                          selected: isSelected,
                          selectedColor: Color(catColorInt),
                          onSelected: (_) {
                            setModalState(() => selectedCategory = catName);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('مدة التحدي: '),
                        const Spacer(),
                        ChoiceChip(
                          label: const Text('7 أيام'),
                          selected: durationDays == 7,
                          onSelected: (_) => setModalState(() => durationDays = 7),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('14 يوم'),
                          selected: durationDays == 14,
                          onSelected: (_) => setModalState(() => durationDays = 14),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('30 يوم'),
                          selected: durationDays == 30,
                          onSelected: (_) => setModalState(() => durationDays = 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      tileColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: const Icon(Icons.notifications_active, color: Color(0xFF10B981)),
                      title: const Text('موعد التذكير اليومي'),
                      trailing: Text(
                        selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim().isEmpty
                              ? 'تحدي $selectedCategory'
                              : titleController.text.trim();
                          setState(() {
                            challenges.add({
                              'title': title,
                              'category': selectedCategory,
                              'time': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              'targetDays': durationDays,
                              'completedDays': 0,
                            });
                          });
                          _saveData();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'بدء التحدي الآن 🔥',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int userLevel = (totalPoints ~/ 100) + 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'منبه العادات والتحديات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          tabs: const [
            Tab(icon: Icon(Icons.alarm), text: 'التنبيهات اليومية'),
            Tab(icon: Icon(Icons.emoji_events), text: 'التحديات والأهداف'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المستوى الحالي: $userLevel 🌟',
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalPoints نقطة',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'أتمم تنبيهاتك وتحدياتك لجمع المزيد!',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 44,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRemindersList(),
                _buildChallengesList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: Colors.black,
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddReminderSheet();
          } else {
            _showAddChallengeSheet();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'إضافة جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRemindersList() {
    if (reminders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'لا توجد تنبيهات حالياً.\nاضغط على "إضافة جديد" لضبط تنبيه صلاة، مذاكرة، تمرين أو دواء!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final item = reminders[index];
        final String catName = (item['category'] ?? 'صلاة الفجر').toString();
        final String noteText = (item['note'] ?? '').toString();
        final String timeText = (item['time'] ?? '00:00').toString();
        final Color catColor = _getCategoryColor(catName);
        final IconData catIcon = _getCategoryIcon(catName);

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0F172A),
              radius: 24,
              child: Icon(catIcon, color: catColor, size: 26),
            ),
            title: Text(
              catName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (noteText.isNotEmpty)
                  Text(noteText, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 15, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Text(
                      timeText,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'إتمام المهمة (+10 نقاط)',
                  icon: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 30),
                  onPressed: () {
                    _addPoints(10, 'أحسنت في إتمام: $catName');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    setState(() => reminders.removeAt(index));
                    _saveData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChallengesList() {
    if (challenges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'لا توجد تحديات نشطة.\nابدأ تحدياً جديداً (مثل تمرين يومي أو قراءة) واجمع النقاط!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final chal = challenges[index];
        final String titleText = (chal['title'] ?? 'تحدي').toString();
        final String catName = (chal['category'] ?? 'تمرين رياضي').toString();
        final String timeText = (chal['time'] ?? '00:00').toString();
        final int completed = (chal['completedDays'] as int?) ?? 0;
        final int target = (chal['targetDays'] as int?) ?? 7;
        final double progress = (completed / target).clamp(0.0, 1.0);
        final bool isFinished = completed >= target;
        final Color catColor = _getCategoryColor(catName);

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getCategoryIcon(catName), color: catColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        titleText,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '⏰ $timeText',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.white38),
                      onPressed: () {
                        setState(() => challenges.removeAt(index));
                        _saveData();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF0F172A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFinished ? Colors.amber : const Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإنجاز: $completed من $target يوم',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (!isFinished)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            challenges[index]['completedDays'] = completed + 1;
                          });
                          if (completed + 1 >= target) {
                            _addPoints(100, 'مبروك! أتممت التحدي بالكامل وحصلت على المكافأة الكبرى');
                          } else {
                            _addPoints(20, 'إنجاز يوم جديد في التحدي!');
                          }
                        },
                        icon: const Icon(Icons.bolt, size: 18),
                        label: const Text('أتممت اليوم (+20)'),
                      )
                    else
                      const Chip(
                        backgroundColor: Colors.amber,
                        label: Text(
                          'مكتمل 🏆',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}