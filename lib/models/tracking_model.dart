import 'package:latlong2/latlong.dart';

class ActiveCourierModel {
  final int courierId;
  final String courierName;
  final String? phone;
  final double latitude;
  final double longitude;
  final String? lastLocationUpdate;
  final bool isOnline;
  final int activeOrderCount;
  final List<ActiveOrderModel> activeOrders;

  ActiveCourierModel({
    required this.courierId,
    required this.courierName,
    this.phone,
    required this.latitude,
    required this.longitude,
    this.lastLocationUpdate,
    required this.isOnline,
    required this.activeOrderCount,
    required this.activeOrders,
  });

  factory ActiveCourierModel.fromJson(Map<String, dynamic> json) {
    var list = json['active_orders'] as List? ?? [];
    List<ActiveOrderModel> ordersList = list.map((i) => ActiveOrderModel.fromJson(i)).toList();

    return ActiveCourierModel(
      courierId: json['courier_id'],
      courierName: json['courier_name'],
      phone: json['phone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      lastLocationUpdate: json['last_location_update'],
      isOnline: json['is_online'],
      activeOrderCount: json['active_order_count'],
      activeOrders: ordersList,
    );
  }

  LatLng get position => LatLng(latitude, longitude);
}

class ActiveOrderModel {
  final int orderId;
  final String status;
  final double pickupLatitude;
  final double pickupLongitude;
  final double deliveryLatitude;
  final double deliveryLongitude;

  ActiveOrderModel({
    required this.orderId,
    required this.status,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
  });

  factory ActiveOrderModel.fromJson(Map<String, dynamic> json) {
    return ActiveOrderModel(
      orderId: json['order_id'],
      status: json['status'],
      pickupLatitude: json['pickup_latitude'],
      pickupLongitude: json['pickup_longitude'],
      deliveryLatitude: json['delivery_latitude'],
      deliveryLongitude: json['delivery_longitude'],
    );
  }

  LatLng get pickupPosition => LatLng(pickupLatitude, pickupLongitude);
  LatLng get deliveryPosition => LatLng(deliveryLatitude, deliveryLongitude);
}
