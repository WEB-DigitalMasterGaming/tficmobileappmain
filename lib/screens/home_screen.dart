import 'package:flutter/material.dart';
import 'package:tficmobileapp/config/theme.dart';
import 'package:tficmobileapp/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgPrimary,
              bgPrimary,
              bgCard,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentBlue, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.medical_services,
                      size: 60,
                      color: accentBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'TFIC Mobile',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Task Force Intelligence Command',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Features Grid
                _buildFeatureCard(
                  icon: Icons.medical_services,
                  title: 'Medical SOS',
                  description: 'Quick access to emergency medical assistance',
                  color: medicalRed,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.event,
                  title: 'Events',
                  description: 'Stay updated with upcoming org events and RSVP',
                  color: accentBlue,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.flag,
                  title: 'Missions',
                  description: 'Accept and complete missions to earn points',
                  color: warningColor,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.library_books,
                  title: 'Knowledge Base',
                  description: 'Access guides, tutorials, and documentation',
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.feedback,
                  title: 'Feedback',
                  description: 'Submit feedback and track your requests',
                  color: successColor,
                ),
                const SizedBox(height: 40),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: accentBlue.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Info Text
                Text(
                  'Members only. Please sign in to access.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
