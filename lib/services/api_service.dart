import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Use 10.0.2.2 for Android emulator
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
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

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': email,
        'password': password,
      }, options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ));

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        await _storage.write(key: 'jwt_token', value: token);
        
        // Fetch user profile
        return await getMe();
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
    return null;
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
    } catch (e) {
      print('GetMe error: $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}

final apiService = ApiService();
