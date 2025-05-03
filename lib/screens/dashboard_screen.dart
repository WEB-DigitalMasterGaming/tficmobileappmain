import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:tficmobileapp/services/api_service.dart';
import 'package:tficmobileapp/utils/auth_storage.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

const Color accentBlue = Color(0xFF3DAEFF); // neon-style blue

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    final user = await ApiService.getUserProfile();
    final events = await ApiService.getMyRsvpEvents();

    events.sort((a, b) => DateTime.parse(a['start']).compareTo(DateTime.parse(b['start']))); // 👈 Sort by start time

    setState(() {
      userData = user;
      userEvents = events;
      isLoading = false;
    });
  }


  void logout() async {
    await AuthStorage.clearToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _showEventDetailsModal(Map<String, dynamic> event) {
    final localStart = DateTime.parse(event['start']).toLocal();
    final formatted = DateFormat('M/d @ h:mm a').format(localStart);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(event['title'] ?? 'Event Details', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: $formatted', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Your Role: ${event['role'] ?? 'Unknown'}', style: const TextStyle(color: accentBlue)),
              const SizedBox(height: 16),
              if (event['description'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Html(
                  data: event['description'],
                  style: {
                    '*': Style(color: Colors.white),
                    'strong': Style(color: accentBlue, fontWeight: FontWeight.bold),
                    'p': Style(color: Colors.white),
                    'li': Style(color: Colors.white),
                  },
                ),
              ),
              if (event['eventImageUrl'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Image.network(event['eventImageUrl']),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: accentBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TFIC Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: const Color(0xFF1E1E2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (userData?['avatarUrl'] != null)
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(userData!['avatarUrl']),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome, ${userData?['username'] ?? 'Unknown'}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A40),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'User Information',
                                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _infoRow('Game Name', userData?['gameUserName']),
                              _infoRow('Discord', userData?['discordName']),
                              _infoRow('Role', userData?['role']),
                            ],
                          ),
                        ),
                        if (userData?['primaryPositionTitle'] != null ||
                          userData?['secondaryPositionTitle'] != null ||
                          userData?['tertiaryPositionTitle'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A40),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Your Positions', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              if (userData?['primaryPositionTitle'] != null)
                                _positionButton(
                                  'Primary',
                                  userData!['primaryPositionTitle'] ?? 'Unknown',
                                  userData!['primaryPositionDescription'] ?? 'No description provided.',
                                ),
                              if (userData?['secondaryPositionTitle'] != null)
                                _positionButton(
                                  'Secondary',
                                  userData!['secondaryPositionTitle'] ?? 'Unknown',
                                  userData!['secondaryPositionDescription'] ?? 'No description provided.',
                                ),
                              if (userData?['tertiaryPositionTitle'] != null)
                                _positionButton(
                                  'Tertiary',
                                  userData!['tertiaryPositionTitle'] ?? 'Unknown',
                                  userData!['tertiaryPositionDescription'] ?? 'No description provided.',
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              await Navigator.pushNamed(context, '/all-events');
                              fetchUser(); // 🔄 Refresh your RSVP data after returning
                            },
                            child: const Text('View All Events', style: TextStyle(color: accentBlue)),
                          ),
                        ),
                        if (userEvents.isEmpty)
                          const Text('No upcoming RSVPs.', style: TextStyle(color: Colors.white70))
                        else
                          ...userEvents.map((event) {
                           final localStart = DateTime.parse(event['start']).toLocal();
                           final formatted = DateFormat('M/d @ h:mm a').format(localStart); // → 5/3 @ 6:00 PM

                            return GestureDetector(
                              onTap: () => _showEventDetailsModal(event),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A40),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: accentBlue.withOpacity(0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(event['title'] ?? 'Unnamed Event',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text('Time: $formatted', style: const TextStyle(color: Colors.white70)),
                                    Row(
                                      children: [
                                        if (event['roleIcon'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: Image.network(
                                              event['roleIcon'],
                                              width: 20,
                                              height: 20,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 20, color: accentBlue),
                                            ),
                                          ),
                                        Text(
                                          'Role: ${event['role'] ?? 'Unknown'}',
                                          style: const TextStyle(color: accentBlue),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () async {
                                          final success = await ApiService.cancelRsvp(event['id']);
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('RSVP canceled.')),
                                            );
                                            fetchUser();
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Failed to cancel RSVP.')),
                                            );
                                          }
                                        },
                                        child: const Text('Cancel RSVP', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Flexible(
            child: Text(
              value.toString(),
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
  Widget _positionButton(String label, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.info_outline, size: 18),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue.withOpacity(0.15),
          foregroundColor: accentBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        label: Text('$label: $title', style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('$label Position', style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: accentBlue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(description, style: const TextStyle(color: Colors.white70)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: accentBlue)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _positionTag(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentBlue.withOpacity(0.1),
        border: Border.all(color: accentBlue.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge, size: 18, color: accentBlue),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: $value',
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

}
