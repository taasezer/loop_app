import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/tracking_model.dart';

class TrackingService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  TrackingService() {
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

  // Get active couriers and their locations
  Future<List<ActiveCourierModel>> getActiveCouriers() async {
    try {
      final response = await _dio.get('/tracking/active');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['couriers'] != null) {
          final List<dynamic> couriersList = data['couriers'];
          return couriersList.map((c) => ActiveCourierModel.fromJson(c)).toList();
        }
      }
    } catch (e) {
      print('Error fetching active couriers: $e');
    }
    return [];
  }

  // Update courier location via REST API (to save to DB)
  Future<void> updateLocation(int courierId, double lat, double lng) async {
    try {
      await _dio.post('/tracking/update', data: {
        'courier_id': courierId,
        'latitude': lat,
        'longitude': lng,
      });
    } catch (e) {
      print('Error updating location to REST API: $e');
    }
  }
  // Assign order using AI engine
  Future<void> assignOrderWithAI(int orderId) async {
    try {
      await _dio.post('/ai/assign', data: {'order_id': orderId});
    } catch (e) {
      print('Error assigning order with AI: $e');
    }
  }
}

final trackingService = TrackingService();
