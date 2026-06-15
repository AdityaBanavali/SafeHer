import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'dart:developer' as developer;
import 'emergency_dashboard.dart';
import 'menstrual_cycle_page.dart';
import 'analysis_page.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    developer.log('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(ChangeNotifierProvider(create: (_) => ThemeProvider(), child: const MyApp()));
}

final log = Logger('SafeHer');

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, tp, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: tp.themeMode,
      home: const MainNavigation(),
    ));
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  final List<Widget> _pages = [const EmergencyDashboard(), const MenstrualCyclePage(), const AnalysisPage()];

  @override
  void initState() {
    super.initState();
    _setupAlertListener();
  }

  void _setupAlertListener() {
    FirebaseDatabase.instance.ref('alerts').onChildAdded.listen((event) async {
      if (event.snapshot.value == null) return;
      final alert = Map<String, dynamic>.from(event.snapshot.value as Map);
      final alertKey = event.snapshot.key!;

      if (alert['status'] == 'active' && !alert.containsKey('time')) {
        await FirebaseDatabase.instance.ref('alerts').child(alertKey).update({
          'time': DateTime.now().toIso8601String(),
        });
        await NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch.toSigned(31),
          title: '⚠️ EMERGENCY',
          body: 'Fall detected!',
          payload: 'emergency',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.warning), label: "Alerts"),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: "Cycle"),
          NavigationDestination(icon: Icon(Icons.analytics), label: "Insights"),
        ],
      ),
    );
  }
}
