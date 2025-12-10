import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tficmobileapp/services/api_service.dart';
import 'package:tficmobileapp/config/theme.dart';

import 'package:tficmobileapp/screens/login_screen.dart';
import 'package:tficmobileapp/screens/dashboard_screen.dart';
import 'package:tficmobileapp/screens/all_events_screen.dart';
import 'package:tficmobileapp/screens/medical_sos_screen.dart';
import 'package:tficmobileapp/screens/missions_screen.dart';
import 'package:tficmobileapp/screens/knowledge_base_screen.dart';
import 'package:tficmobileapp/screens/feedback_screen.dart';
import 'package:tficmobileapp/screens/user_profile_screen.dart';
import 'package:tficmobileapp/utils/auth_storage.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Init local notification settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void setupMessageListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📨 Foreground message: \${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel_id',
            'Default Notifications',
            channelDescription: 'For showing notifications while app is in foreground',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📲 App opened via notification');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupFirebaseMessaging();
  setupMessageListeners();

  await FirebaseMessaging.instance.subscribeToTopic("events"); // ✅ Subscribes to "events"
  
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('📲 FCM Token: $fcmToken');

  if (fcmToken != null) {
    await ApiService.sendFcmTokenToBackend(fcmToken);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'TFIC Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1A1A28),
          cardColor: const Color(0xFF1E1E2E),
          primaryColor: accentBlue,
          colorScheme: const ColorScheme.dark(
            primary: accentBlue,
            secondary: accentBlue,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: accentBlue,
            ),
          ),
          iconTheme: const IconThemeData(color: accentBlue),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A28),
            iconTheme: IconThemeData(color: accentBlue),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/login': (context) => LoginScreen(),
          '/all-events': (context) => const AllEventsScreen(),
          '/medical-sos': (context) => const MedicalSosScreen(),
          '/missions': (context) => const MissionsScreen(),
          '/knowledge-base': (context) => const KnowledgeBaseScreen(),
          '/feedback': (context) => const FeedbackScreen(),
          '/profile': (context) => const UserProfileScreen(),
        },
        home: FutureBuilder<bool>(
          future: AuthStorage.hasToken(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (snapshot.data == true) {
              return const DashboardScreen();
            } else {
              return LoginScreen();
            }
          },
        ),
      );
    }

}
