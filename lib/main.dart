import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootApp());
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  StorageService? _storage;
  String _status = 'Starting notifications...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await NotificationService.instance
          .init()
          .timeout(const Duration(seconds: 10));

      if (mounted) setState(() => _status = 'Opening storage...');
      await Hive.initFlutter().timeout(const Duration(seconds: 10));
      final s = StorageService();
      await s.init().timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() => _storage = s);

      // Ask for permissions after the UI is visible, without blocking startup.
      NotificationService.instance.requestPermissions();
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _error = 'Failed at: $_status\n\n$e\n\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = _storage;

    Widget home;
    if (_error != null) {
      home = Scaffold(
        appBar: AppBar(title: const Text('Startup error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(_error!),
        ),
      );
    } else if (storage == null) {
      home = Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_status),
            ],
          ),
        ),
      );
    } else {
      home = const HomeScreen();
    }

    final app = MaterialApp(
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
      home: home,
    );

    if (storage == null) return app;

    // The provider sits above MaterialApp so pushed screens can reach it too.
    return ChangeNotifierProvider<StorageService>.value(
      value: storage,
      child: app,
    );
  }
}