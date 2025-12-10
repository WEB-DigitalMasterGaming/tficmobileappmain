import 'package:flutter/material.dart';
import 'package:tficmobileapp/config/theme.dart';
import 'package:tficmobileapp/screens/dashboard_screen.dart';
import 'package:tficmobileapp/screens/medical_sos_screen.dart';
import 'package:tficmobileapp/screens/missions_screen.dart';
import 'package:tficmobileapp/screens/knowledge_base_screen.dart';
import 'package:tficmobileapp/screens/all_events_screen.dart';
import 'package:tficmobileapp/screens/user_profile_screen.dart';
import 'package:tficmobileapp/screens/feedback_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MedicalSosScreen(),
    const MissionsScreen(),
    const KnowledgeBaseScreen(),
    const AllEventsScreen(),
    const UserProfileScreen(),
    const FeedbackScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: bgCard,
        selectedItemColor: accentBlue,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Medical SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Knowledge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }
}
