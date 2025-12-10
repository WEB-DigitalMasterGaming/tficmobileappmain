import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:tficmobileapp/utils/auth_storage.dart';
import 'package:tficmobileapp/config/environment.dart';

class ApiService {
  static String get baseUrl => Environment.apiUrl;

  static Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Username': username,
        'Password': password,
      }),
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await AuthStorage.getToken();
        if (token == null) return null;

        final url = Uri.parse('$baseUrl/auth/user/profile'); // ✅ CORRECTED ROUTE
        final response = await http.get(
            url,
            headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            },
        );

        if (response.statusCode == 200) {
            return json.decode(response.body);
        } else {
            debugPrint('Failed to load profile: ${response.statusCode}');
            return null;
        }
    }

    static Future<List<Map<String, dynamic>>> getMyRsvpEvents() async {
        final token = await AuthStorage.getToken();
        if (token == null) return [];

        final response = await http.get(
            Uri.parse('$baseUrl/events/my-rsvps'),
            headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            },
        );

        if (response.statusCode == 200) {
            return List<Map<String, dynamic>>.from(json.decode(response.body));
        } else {
            debugPrint('Failed to fetch RSVP events: ${response.statusCode}');
            return [];
        }
    }

    static Future<bool> cancelRsvp(int eventId) async {
      try {
        final token = await AuthStorage.getToken();
        final user = await getUserProfile();
        if (token == null || user == null || user['username'] == null) return false;

        // Authenticated GET request to fetch the event
       final eventResponse = await http.get(
        Uri.parse('$baseUrl/events/public/$eventId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (eventResponse.statusCode != 200) {
          print('❌ Failed to fetch event: ${eventResponse.statusCode}');
          return false;
        }

        final event = json.decode(eventResponse.body);
        final rsvps = event['rsvps'] as List<dynamic>;
        final matching = rsvps.firstWhere(
          (r) =>
              r['attending'] == true &&
              r['username']?.toString().toLowerCase() ==
                  user['username'].toString().toLowerCase(),
          orElse: () => null,
        );

        final role = matching?['role'];
        if (role == null) return false;

        final cancelResponse = await http.post(
          Uri.parse('$baseUrl/events/rsvp'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'eventId': eventId,
            'username': user['username'],
            'attending': false,
            'source': 'mobile',
            'role': role,
          }),
        );

        return cancelResponse.statusCode == 200;
      } catch (e) {
        print('❌ Cancel RSVP failed: $e');
        return false;
      }
    }

    static Future<List<Map<String, dynamic>>> getAllEvents() async {
      final token = await AuthStorage.getToken();
      if (token == null) return [];

      // Get events from now to 7 days out
      final now = DateTime.now();
      final sevenDaysOut = now.add(const Duration(days: 7));
      final startDate = now.toIso8601String();
      final endDate = sevenDaysOut.toIso8601String();

      final response = await http.get(
        Uri.parse('$baseUrl/events?startDate=$startDate&endDate=$endDate&excludeImages=true'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        debugPrint('❌ Failed to load all events: ${response.statusCode}');
        return [];
      }
    }

    static Future<Map<String, dynamic>?> getEventById(int eventId) async {
      final token = await AuthStorage.getToken();
      if (token == null) return null;

      try {
        final response = await http.get(
          Uri.parse('$baseUrl/events/$eventId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
        return null;
      } catch (e) {
        debugPrint('❌ Error loading event details: $e');
        return null;
      }
    }

    static Future<bool> rsvpToEvent(int eventId, String roleName) async {
      try {
        final token = await AuthStorage.getToken();
        final user = await getUserProfile();
        if (token == null || user == null) return false;

        final response = await http.post(
          Uri.parse('$baseUrl/events/rsvp'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'eventId': eventId,
            'username': user['username'],
            'attending': true,
            'source': 'mobile',
            'role': roleName,
          }),
        );

        return response.statusCode == 200;
      } catch (e) {
        print('❌ RSVP failed: $e');
        return false;
      }
    }

    static Future<void> sendFcmTokenToBackend(String fcmToken) async {
      final token = await AuthStorage.getToken();
      if (token == null) {
        debugPrint('❌ Cannot send FCM token: no auth token found.');
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/push/register-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token sent to backend.');
      } else {
        debugPrint('❌ Failed to send FCM token: ${response.statusCode} - ${response.body}');
      }
    }

  // Medical SOS methods
  static Future<Map<String, dynamic>?> getMyActiveTicket() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/MedicalTickets/my-active'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting my active ticket: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableTickets() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/MedicalTickets/available'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Error getting available tickets: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllTicketHistory() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/MedicalTickets/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Error getting all ticket history: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTicketReports({required DateTime startDate, required DateTime endDate}) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return {};

      // Convert to UTC for PostgreSQL compatibility
      final startUtc = startDate.toUtc();
      final endUtc = endDate.toUtc();
      final url = '$baseUrl/medicaltickets/reports?startDate=${startUtc.toIso8601String()}&endDate=${endUtc.toIso8601String()}';
      debugPrint('📊 Fetching reports: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📊 Reports response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📊 Reports data: $data');
        return data;
      }
      debugPrint('📊 Reports error: ${response.body}');
      return {};
    } catch (e) {
      debugPrint('❌ Error getting ticket reports: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getTicketMessages(int ticketId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/MedicalTickets/$ticketId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Error getting ticket messages: $e');
      return [];
    }
  }

  static Future<bool> sendTicketMessage(int ticketId, String message) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return false;

      final body = json.encode({'message': message});
      debugPrint('📤 Sending message to ticket $ticketId: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/MedicalTickets/$ticketId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('📨 Message send response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Error sending ticket message: $e');
      return false;
    }
  }

  static Future<bool> claimTicket(int ticketId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/MedicalTickets/$ticketId/claim'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error claiming ticket: $e');
      return false;
    }
  }

  static Future<bool> completeTicket(int ticketId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/MedicalTickets/$ticketId/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error completing ticket: $e');
      return false;
    }
  }

  static Future<bool> cancelTicket(int ticketId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/MedicalTickets/$ticketId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error cancelling ticket: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> createMedicalTicket({
    required String inGameUsername,
    required String currentSystem,
    required String currentLocation,
    int? deathTimerRemaining,
    String? notes,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/MedicalTickets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'inGameUsername': inGameUsername,
          'currentSystem': currentSystem,
          'currentLocation': currentLocation,
          'deathTimerRemaining': deathTimerRemaining,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating medical ticket: $e');
      return null;
    }
  }

  // Missions methods
  static Future<List<Map<String, dynamic>>> getMissionBoard() async {
    final token = await AuthStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/missions/board'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching mission board: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMyMissions() async {
    final token = await AuthStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/missions/my'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my missions: $e');
      return [];
    }
  }

  static Future<bool> acceptMission(int missionId) async {
    final token = await AuthStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/missions/$missionId/accept'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error accepting mission: $e');
      return false;
    }
  }

  static Future<bool> completeMission(int acceptanceId) async {
    final token = await AuthStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/missions/$acceptanceId/submit-complete'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error completing mission: $e');
      return false;
    }
  }

  static Future<bool> abandonMission(int acceptanceId) async {
    final token = await AuthStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/missions/$acceptanceId/release'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error abandoning mission: $e');
      return false;
    }
  }

  // Knowledge Base methods
  static Future<List<String>> getKnowledgeCategories() async {
    final token = await AuthStorage.getToken();
    if (token == null) return [];

    try {
      final url = '$baseUrl/knowledgebase/categories';
      debugPrint('📚 Fetching KB categories: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('📚 KB categories response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('📚 Found ${data.length} categories: $data');
        return data.cast<String>();
      }
      debugPrint('📚 KB categories error: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching KB categories: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getKnowledgeArticles({String? category, String? search}) async {
    final token = await AuthStorage.getToken();
    if (token == null) return [];

    try {
      var url = '$baseUrl/knowledgebase/articles';
      final params = <String>[];
      if (category != null) params.add('category=$category');
      if (search != null) params.add('search=$search');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      debugPrint('📚 Fetching KB articles: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('📚 KB articles response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle paginated response
        if (data is Map && data.containsKey('articles')) {
          final List<dynamic> articles = data['articles'];
          debugPrint('📚 Found ${articles.length} articles');
          return articles.cast<Map<String, dynamic>>();
        }
        // Handle plain array response (backward compatibility)
        else if (data is List) {
          debugPrint('📚 Found ${data.length} articles');
          return data.cast<Map<String, dynamic>>();
        }
      }
      debugPrint('📚 KB articles error: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching KB articles: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getKnowledgeArticleBySlug(String slug) async {
    final token = await AuthStorage.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/knowledgebase/articles/$slug'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching KB article: $e');
      return null;
    }
  }

  static Future<void> markArticleAsRead(String slug) async {
    final token = await AuthStorage.getToken();
    if (token == null) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/knowledgebase/articles/$slug/mark-read'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('Error marking article as read: $e');
    }
  }

  // Feedback methods
  static Future<List<Map<String, dynamic>>> getMyFeedback() async {
    final token = await AuthStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feedback/my'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching feedback: $e');
      return [];
    }
  }

  static Future<bool> submitFeedback({required String pageScope, required String category, required String message, required String priority}) async {
    final token = await AuthStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pageScope': pageScope,
          'category': category,
          'message': message,
          'priority': priority,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }

  // Points History method
  static Future<List<Map<String, dynamic>>> getPointsHistory() async {
    final token = await AuthStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/points-history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching points history: $e');
      return [];
    }
  }

}
