import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SignUpService {
  final String apiUrl = 'http://localhost:5001';

  Future<void> signUp(String email, String password, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password, 'name': name}),
      );

      
        var data = json.decode(response.body);

        // Saving tokens to a file
        await saveTokensToFile(data['access_token'], data['refresh_token']);

        print('User successfully signed up and tokens saved.');
      
    } catch (e) {
      print('SignUp Error: $e');
    }
  }
}

