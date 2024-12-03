import 'sign_in_service.dart';
import 'sign_up_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:rapid_gourmet/Page/myhome_page.dart';  // импортируем страницу
import 'package:flutter/material.dart';
import 'package:rapid_gourmet/main.dart'; 

// Saving tokens to a file
Future<void> saveTokensToFile(String accessToken, String refreshToken) async {
  final filePath =
      '/Users/artem/Downloads/sem2/flutter_projects/rapid_gourmet/lib/services/token.json';

  final tokenData = {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };

  final file = File(filePath);

  // Creating a file if there is none
  if (!(await file.exists())) {
    await file.create(recursive: true);
  }

  // Writing tokens to a file
  await file.writeAsString(json.encode(tokenData),
      mode: FileMode.write, flush: true);
}

class AuthService {
  final SignInService _signInService = SignInService();
  final SignUpService _signUpService = SignUpService();
  final String baseUrl = 'http://localhost:5001'; // Server URL
  final String tokenFilePath =
      '/Users/artem/Downloads/sem2/flutter_projects/rapid_gourmet/lib/services/token.json';

  // Loading tokens from a file
  Future<Map<String, String>?> loadTokensFromFile() async {
    final file = File(tokenFilePath);

    if (await file.exists()) {
      final tokenData = json.decode(await file.readAsString());
      return {
        'accessToken': tokenData['accessToken'],
        'refreshToken': tokenData['refreshToken'],
      };
    }
    return null;
  }

// updating tokens
  Future<bool> updateTokens() async {
    final tokens = await loadTokensFromFile();
    if (tokens == null || tokens['refreshToken'] == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/updateTokens'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh_token': tokens['refreshToken']}),
    );

    if (response.statusCode == 200) {
      final newTokens = json.decode(response.body);
      await saveTokensToFile(
          newTokens['access_token'], newTokens['refresh_token']);
      return true;
    }else{
      return false; // Failed to update tokens
    }
  }

  // Auxiliary method for sending requests
  Future<http.Response> _sendRequest(
      String endpoint, String method, dynamic body, String? accessToken) {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };

    switch (method.toUpperCase()) {
      case 'POST':
        return http.post(url, headers: headers, body: json.encode(body));
      case 'GET':
        return http.get(url, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }


  // Executing a request with automatic token renewal
  Future<http.Response> makeAuthenticatedRequest(
      String endpoint, String method, dynamic body) async {
    var tokens = await loadTokensFromFile();
    if (tokens == null) throw Exception('Tokens not found');
    var response =
        await _sendRequest(endpoint, method, body, tokens['accessToken']);

    // If the token has expired, we try to update the tokens and repeat the request
    if (response.statusCode == 403) {
      final refreshed = await updateTokens();
      if (refreshed) {
        tokens = await loadTokensFromFile();
        response =
            await _sendRequest(endpoint, method, body, tokens!['accessToken']);
      }else {
        navigateToHomePage();
      }
    }

    return response;
  }

   // Метод для выполнения перехода на главную страницу
  void navigateToHomePage() {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => MyHomePage()),
    );
  }

  Future<Map<String, dynamic>?> signIn(String email, String password) {
    return _signInService.signIn(email, password);
  }

  Future<void> signUp(String email, String password, String name) {
    return _signUpService.signUp(email, password, name);
  }
}
