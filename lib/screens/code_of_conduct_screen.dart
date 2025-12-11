import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

class CodeOfConductScreen extends StatelessWidget {
  final bool showAcceptButton;

  const CodeOfConductScreen({super.key, this.showAcceptButton = true});

  Future<void> _acceptCodeOfConduct(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checklistProgress.codeOfConduct', true);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Code of Conduct accepted'),
          backgroundColor: successColor,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true); // Return true to indicate acceptance
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        title: const Text('Code of Conduct 🛡️'),
        backgroundColor: bgCard,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentBlue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to TFIC!',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Our Code of Conduct ensures a respectful and inclusive environment for all members. Please read and understand these guidelines:',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Code of Conduct Sections
              _buildSection(
                '1. Respect All Members',
                'Treat everyone with dignity and respect. Harassment, discrimination, hate speech, or personal attacks will not be tolerated.',
              ),
              
              _buildSection(
                '2. Communication Standards',
                'Keep discussions constructive and professional. Excessive profanity, spam, or disruptive behavior is prohibited.',
              ),
              
              _buildSection(
                '3. Gaming Conduct',
                'Play fair and follow game rules. Cheating, exploiting, or griefing other players is strictly forbidden.',
              ),
              
              _buildSection(
                '4. Confidentiality',
                'Respect privacy and don\'t share personal information without consent. Internal org discussions should remain confidential.',
              ),
              
              _buildSection(
                '5. Leadership & Hierarchy',
                'Follow chain of command and respect leadership decisions. Disagreements should be handled professionally through proper channels.',
              ),
              
              _buildSection(
                '6. Content Guidelines',
                'Keep all content appropriate for all ages. No NSFW, illegal, or controversial political/religious content.',
              ),
              
              _buildSection(
                '7. Account Security',
                'Keep your account secure. Account sharing or impersonation is prohibited.',
              ),
              
              _buildSection(
                '8. Reporting Issues',
                'Report violations to leadership immediately. False reports or retaliation against reporters will result in disciplinary action.',
              ),

              const SizedBox(height: 16),

              // Warning Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Violations may result in warnings, suspension, or permanent removal from the organization.',
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Accept Button (if shown)
              if (showAcceptButton) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _acceptCodeOfConduct(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'I Accept the Code of Conduct',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: textMuted.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
