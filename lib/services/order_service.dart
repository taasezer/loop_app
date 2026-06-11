import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/order_model.dart'; 

class OrderService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  OrderService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // Get available orders for courier
  Future<List<OrderModel>> getAvailableOrders() async {
    try {
      final response = await _dio.get('/courier/orders/available');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrderModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching available orders: $e');
    }
    return [];
  }

  // Accept an order
  Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await _dio.post('/courier/orders/$orderId/accept');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error accepting order: $e');
      return false;
    }
  }

  // Reject an order
  Future<bool> rejectOrder(String orderId) async {
    try {
      final response = await _dio.post('/courier/orders/$orderId/reject');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error rejecting order: $e');
      return false;
    }
  }

  // Update order status (pickup, start delivery, complete)
  Future<bool> updateOrderStatus(String orderId, String action) async {
    try {
      // action can be: 'pickup', 'start-delivery', 'complete'
      final response = await _dio.post('/courier/orders/$orderId/$action');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error updating order status ($action): $e');
      return false;
    }
  }
  
  // Get courier's active/past orders
  Future<List<OrderModel>> getMyOrders() async {
     try {
      final response = await _dio.get('/courier/orders/my-orders');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrderModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching my orders: $e');
    }
    return [];
  }
}

final orderService = OrderService();
