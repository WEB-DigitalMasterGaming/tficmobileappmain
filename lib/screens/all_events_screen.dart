import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:tficmobileapp/services/api_service.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  List<Map<String, dynamic>> allEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

 Future<void> fetchEvents() async {
    final events = await ApiService.getAllEvents();

    events.sort((a, b) => DateTime.parse(a['start']).compareTo(DateTime.parse(b['start']))); // 👈 Sort chronologically

    setState(() {
      allEvents = events;
      isLoading = false;
    });
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
              if (event['description'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Html(
                    data: event['description'],
                    style: {
                      '*': Style(color: Colors.white),
                      'strong': Style(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
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
              if (event['roles'] != null && event['roles'] is List)
                Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text('RSVP Roles:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...List<Widget>.from(
                        event['roles'].map<Widget>((role) {
                            final attendees = (event['rsvps'] as List)
                                .where((r) => r['role'] == role['name'] && r['attending'] == true)
                                .toList();

                            final roleFull = role['capacity'] != null &&
                                attendees.length >= role['capacity'];

                            return ListTile(
                            title: Text(
                                '${role['icon'] ?? ''} ${role['name']}',
                                style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                                '${attendees.length}/${role['capacity'] ?? '∞'} attending',
                                style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: ElevatedButton(
                                onPressed: roleFull
                                    ? null
                                    : () async {
                                        final success = await ApiService.rsvpToEvent(
                                        event['id'],
                                        role['name'],
                                        );
                                        Navigator.of(context).pop();
                                        if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('RSVP submitted!')),
                                        );
                                        fetchEvents(); // refresh UI
                                        } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Failed to RSVP.')),
                                        );
                                        }
                                    },
                                child: const Text('RSVP'),
                            ),
                            );
                        }),
                        )
                    ],
                    ),
                ),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.deepPurpleAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allEvents.isEmpty
              ? const Center(child: Text('No events found.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: allEvents.length,
                  itemBuilder: (context, index) {
                    final event = allEvents[index];
                    final localStart = DateTime.parse(event['start']).toLocal();
                    final formatted = DateFormat('M/d @ h:mm a').format(localStart);

                    return GestureDetector(
                      onTap: () => _showEventDetailsModal(event),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A40),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['title'] ?? 'Unnamed Event',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Time: $formatted', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
