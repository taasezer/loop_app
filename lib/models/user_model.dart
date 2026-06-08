class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String? supplierCode;
  final String? companyName;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.supplierCode,
    this.companyName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      isActive: json['is_active'] ?? true,
      supplierCode: json['supplier_code'],
      companyName: json['company_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'supplier_code': supplierCode,
      'company_name': companyName,
    };
  }
}
