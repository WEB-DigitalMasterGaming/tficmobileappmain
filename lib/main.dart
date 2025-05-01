import 'package:flutter/material.dart';
import 'package:tficmobileapp/screens/login_screen.dart';
import 'package:tficmobileapp/screens/dashboard_screen.dart';
import 'package:tficmobileapp/utils/auth_storage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TFIC Mobile',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: AuthStorage.hasToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.data == true) {
            return DashboardScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
