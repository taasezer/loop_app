import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../services/tracking_service.dart';

class WebSocketService {
  static const String wsUrl = 'ws://10.0.2.2:8000/ws';
  WebSocketChannel? _channel;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Function(Map<String, dynamic>)? onMessageReceived;

  Future<void> connect(String userId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      // In a real scenario, you might pass the token as a query param or authenticate after connection
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/$userId'));
      
      _channel?.stream.listen((message) {
        if (onMessageReceived != null) {
          final data = json.decode(message);
          onMessageReceived!(data);
        }
      }, onDone: () {
        print('WebSocket Disconnected');
      }, onError: (error) {
        print('WebSocket Error: $error');
      });
    } catch (e) {
      print('WebSocket connection error: $e');
    }
  }

  void subscribeToOrder(String orderId) {
    if (_channel != null) {
      _channel!.sink.add(json.encode({
        'type': 'join_room',
        'room_id': orderId,
      }));
    }
  }

  void sendLocationUpdate(String orderId, Position position, {int? courierId}) {
    if (_channel != null) {
      _channel!.sink.add(json.encode({
        'type': 'location_update',
        'order_id': orderId,
        'lat': position.latitude,
        'lon': position.longitude,
      }));
      
      // Send location to REST API as well to save in DB
      if (courierId != null) {
        trackingService.updateLocation(courierId, position.latitude, position.longitude);
      }
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}

final wsService = WebSocketService();
