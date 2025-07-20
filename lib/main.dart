import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'widgets/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database
  tz.initializeTimeZones();

  // Set up local notifications
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  try {
    print('Initializing notifications...');
    final initialized = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification response received: ${response.payload}');
      },
    );
    print(
        'Notification initialization ${initialized == true ? 'succeeded' : 'failed'}');
  } catch (e, stack) {
    print('Error initializing notifications: $e');
    print('Stack trace: $stack');
  }

  // Initialize database
  final database = DatabaseService();
  try {
    print('Initializing database...');
    await database.init();
    print('Database initialized.');
  } catch (e, stack) {
    print('Error initializing database: $e');
    print('Stack trace: $stack');
  }

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          Provider.value(value: database),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    print('Unhandled error: $error');
    print('Stack trace: $stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        print('Building MyApp with themeMode: ${themeProvider.themeMode}');
        return MaterialApp(
          title: 'DayDo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: const TextTheme(
              bodySmall: TextStyle(fontSize: 12, color: Colors.black),
              titleSmall: TextStyle(fontSize: 14, color: Colors.black),
              titleLarge: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            textTheme: const TextTheme(
              bodySmall: TextStyle(fontSize: 12, color: Colors.white),
              titleSmall: TextStyle(fontSize: 14, color: Colors.white),
              titleLarge: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
        );
      },
    );
  }
}
