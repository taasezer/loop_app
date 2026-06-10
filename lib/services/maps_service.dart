import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../utils/polyline_decoder.dart';

class MapsService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // Get polyline points from backend's map routing API
  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    try {
      final response = await _dio.post('/maps/route', data: {
        "origin": {
          "latitude": origin.latitude,
          "longitude": origin.longitude
        },
        "destination": {
          "latitude": destination.latitude,
          "longitude": destination.longitude
        }
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['geometry'] != null) {
          final String polylineStr = data['geometry'];
          return PolylineDecoder.decodePolyline(polylineStr);
        }
      }
    } catch (e) {
      print('Error fetching route from backend: $e');
    }
    return [];
  }
}

final mapsService = MapsService();
