import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:tficmobileapp/utils/auth_storage.dart';

class ApiService {
  static const String baseUrl = 'https://api.tficorg.org/api';

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

      final response = await http.get(
        Uri.parse('$baseUrl/events'),
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

}
