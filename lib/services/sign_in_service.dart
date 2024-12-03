import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SignInService {
  final String apiUrl = 'http://localhost:5001';

  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      
        var data = json.decode(response.body);

        // Saving tokens to a file
        await saveTokensToFile(data['access_token'], data['refresh_token']);

        return {  
          'userName': data['userName'],
          'orderCount': data['orderCount'] ?? 0,
          'balance': data['balance'] ?? 0,
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
        };
     
    } catch (e) {
      print('SignIn Error: $e');
      return null;
    }
  }
}
