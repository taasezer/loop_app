class OrderModel {
  final int id;
  final String status;
  final String? externalOrderId;
  final double? totalAmount;
  final String? customerName;
  final String? customerPhone;
  final String? pickupAddress;
  final String? deliveryAddress;
  final String createdAt;
  
  OrderModel({
    required this.id,
    required this.status,
    this.externalOrderId,
    this.totalAmount,
    this.customerName,
    this.customerPhone,
    this.pickupAddress,
    this.deliveryAddress,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      status: json['status'],
      externalOrderId: json['external_order_id'],
      totalAmount: json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : null,
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      pickupAddress: json['pickup_address'],
      deliveryAddress: json['delivery_address'],
      createdAt: json['created_at'],
    );
  }
}
