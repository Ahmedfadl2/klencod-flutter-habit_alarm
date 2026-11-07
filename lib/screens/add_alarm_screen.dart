import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({super.key});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  static const _categories = [
    'صلاة',
    'تمرين',
    'مذاكرة',
    'قرآن',
    'بودكاست',
    'دواء',
    'كتاب',
    'أخرى',
  ];

  final _titleCtrl = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  String _category = _categories.first;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final title =
        _titleCtrl.text.trim().isEmpty ? _category : _titleCtrl.text.trim();
    await context.read<StorageService>().addAlarm(
          title: title,
          category: _category,
          hour: _time.hour,
          minute: _time.minute,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنبيه جديد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'النوع'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'العنوان (اختياري)',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time),
            title: const Text('الوقت'),
            subtitle: Text(_time.format(context)),
            onTap: _pickTime,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('حفظ')),
        ],
      ),
    );
  }
}