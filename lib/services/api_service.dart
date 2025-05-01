import 'dart:convert';
import 'package:http/http.dart' as http;

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
}
