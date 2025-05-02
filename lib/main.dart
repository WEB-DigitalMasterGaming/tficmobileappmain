import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tficmobileapp/services/api_service.dart';

import 'package:tficmobileapp/screens/login_screen.dart';
import 'package:tficmobileapp/screens/dashboard_screen.dart';
import 'package:tficmobileapp/screens/all_events_screen.dart';
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
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/login': (context) => LoginScreen(),
        '/all-events': (context) => const AllEventsScreen(),
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
