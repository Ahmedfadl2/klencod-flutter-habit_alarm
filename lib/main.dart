import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? errorText;
  StorageService? storage;

  // Notifications must be ready before storage re-schedules saved alarms.
  try {
    await NotificationService.instance.init();
  } catch (e, st) {
    errorText = 'Notifications init failed:\n$e\n$st';
  }

  try {
    await Hive.initFlutter();
    final s = StorageService();
    await s.init();
    storage = s;
  } catch (e, st) {
    errorText = '${errorText ?? ''}\n\nStorage init failed:\n$e\n$st';
  }

  // Diagnostic mode: show the error on screen instead of a white screen.
  if (storage == null || errorText != null) {
    runApp(ErrorApp(message: errorText ?? 'Unknown startup error'));
    return;
  }

  runApp(
    ChangeNotifierProvider<StorageService>.value(
      value: storage,
      child: const HabitAlarmApp(),
    ),
  );
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Startup error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(message),
        ),
      ),
    );
  }
}

class HabitAlarmApp extends StatelessWidget {
  const HabitAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF4CAF50),
      ),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
