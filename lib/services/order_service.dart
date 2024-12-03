import 'dart:convert';
import 'auth_service.dart';

class OrderService {
  final AuthService _authService =
      AuthService(); // Creating an instance of AuthService

  // Method for getting user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _authService.makeAuthenticatedRequest(
        '/getUserProfile',
        'GET',
        null, // The request body is not required for GET
      );

      return jsonDecode(response.body);
    } catch (e) {

      print('Error retrieving user profile: $e');
      return null;
    }
  }

  // Method for updating the user's balance
  Future<bool> updateUserBalance(int newBalance) async {
    try {
      final response = await _authService.makeAuthenticatedRequest(
        '/updateBalance', // Endpoint to update the balance
        'POST',
        {
          'balance': newBalance, // We are transferring a new balance
        },
      );

      print('Balance updated successfully'+response.body);
      return true;
    } catch (e) {

      print('Error updating balance: $e');
      return false;
    }
  }

  // Method for creating a new order
  Future<void> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String selectedTime,
    required double totalPrice,
  }) async {
    try {
      final response = await _authService.makeAuthenticatedRequest(
        '/createOrder',
        'POST',
        {
          'items': items, // sending a list of products
          'deliveryAddress': deliveryAddress,
          'selectedTime': selectedTime,
          'totalPrice': totalPrice,
        },
      );

      
      print('Order created successfully'+response.body);
      
    } catch (e) {
      print('Error creating order: $e');
    }
  }


  // Method for getting dishes from the server
  Future<Map<String, dynamic>?> getDishes() async {
    try {
      final response = await _authService.makeAuthenticatedRequest(
        '/getDishes', // Endpoint to fetch dishes
        'GET',
        null, // No request body needed for GET
      );

      if (response.statusCode == 200) {
        // Parse and return the dishes data
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data); // Ensure correct data type
      } else {
        print('Failed to fetch dishes: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching dishes: $e');
      return null;
    }
  }



  // Method for receiving orders by user
  Future<List<Map<String, dynamic>>> getOrdersByUser() async {
    try {
      final response = await _authService.makeAuthenticatedRequest(
        '/getOrdersByUser',
        'GET',
        null, // The request body is not required for GET
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = data['orders'] as List;
        return orders.map((order) => Map<String, dynamic>.from(order)).toList();
      } else {
        print('Failed to fetch orders: ${response.body}');
        throw Exception('Failed to fetch orders');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }
}
