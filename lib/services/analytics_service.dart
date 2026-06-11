import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardStats {
  final int activeCouriers;
  final int deliveredOrders;
  final int delayedOrders;
  final double totalRevenue;
  final double successRate;
  final int totalOrders;

  DashboardStats({
    required this.activeCouriers,
    required this.deliveredOrders,
    required this.delayedOrders,
    required this.totalRevenue,
    required this.successRate,
    required this.totalOrders,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      activeCouriers: 0,
      deliveredOrders: 0,
      delayedOrders: 0,
      totalRevenue: 0.0,
      successRate: 0.0,
      totalOrders: 0,
    );
  }
}

class CourierPerformance {
  final int courierId;
  final int deliveries;
  final double rating;
  final double revenue;
  final bool isOnline;

  CourierPerformance({
    required this.courierId,
    required this.deliveries,
    required this.rating,
    required this.revenue,
    required this.isOnline,
  });

  factory CourierPerformance.fromJson(Map<String, dynamic> json) {
    return CourierPerformance(
      courierId: json['courier_id'] ?? 0,
      deliveries: json['deliveries'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      revenue: (json['revenue_generated'] as num?)?.toDouble() ?? 0.0,
      isOnline: json['is_online'] ?? false,
    );
  }
}

class AnalyticsService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AnalyticsService() {
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

  Future<DashboardStats> getDashboardStats() async {
    try {
      final dashRes = await _dio.get('/analytics/dashboard');
      final metricsRes = await _dio.get('/analytics/delivery-metrics');
      
      int active = 0;
      double revenue = 0;
      int delivered = 0;
      int delayed = 0;
      double success = 0;
      int total = 0;

      if (dashRes.statusCode == 200) {
        active = dashRes.data['active_couriers'] ?? 0;
        revenue = (dashRes.data['total_revenue'] as num?)?.toDouble() ?? 0.0;
      }

      if (metricsRes.statusCode == 200) {
        delivered = metricsRes.data['delivered_orders'] ?? 0;
        delayed = metricsRes.data['in_progress_orders'] ?? 0;
        success = (metricsRes.data['success_rate'] as num?)?.toDouble() ?? 0.0;
        total = metricsRes.data['total_orders'] ?? 0;
      }

      return DashboardStats(
        activeCouriers: active,
        deliveredOrders: delivered,
        delayedOrders: delayed,
        totalRevenue: revenue,
        successRate: success,
        totalOrders: total,
      );
    } catch (e) {
      print('Error fetching analytics: $e');
    }
    return DashboardStats.empty();
  }

  Future<List<CourierPerformance>> getLeaderboard() async {
    try {
      final response = await _dio.get('/analytics/courier-performance');
      if (response.statusCode == 200) {
        final List topPerformers = response.data['top_performers'] ?? [];
        return topPerformers.map((e) => CourierPerformance.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
    }
    return [];
  }
}

final analyticsService = AnalyticsService();
