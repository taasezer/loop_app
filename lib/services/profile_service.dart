import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PerformanceStats {
  final int completedDeliveries;
  final double averageRating;
  final double successRate;
  final int membershipMonths;

  PerformanceStats({
    required this.completedDeliveries,
    required this.averageRating,
    required this.successRate,
    required this.membershipMonths,
  });

  factory PerformanceStats.fromJson(Map<String, dynamic> json) {
    return PerformanceStats(
      completedDeliveries: json['completed_deliveries'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 100.0,
      membershipMonths: json['membership_months'] ?? 1,
    );
  }
}

class ProfileService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ProfileService() {
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

  Future<PerformanceStats?> getPerformance() async {
    try {
      final response = await _dio.get('/couriers/performance');
      if (response.statusCode == 200) {
        return PerformanceStats.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching performance: $e');
    }
    return null;
  }
}

final profileService = ProfileService();
