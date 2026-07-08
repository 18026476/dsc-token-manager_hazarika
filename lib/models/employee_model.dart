class EmployeeModel {
  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final int? departmentId;
  final String managerName;
  final String location;

  EmployeeModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.departmentId,
    required this.managerName,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'department_id': departmentId,
      'manager_name': managerName,
      'location': location,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as int?,
      fullName: map['full_name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      departmentId: map['department_id'] as int?,
      managerName: map['manager_name']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
    );
  }
}
