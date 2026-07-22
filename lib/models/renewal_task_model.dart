class RenewalTaskModel {
  final int? id;
  final String certificateThumbprint;
  final String certificateHolder;
  final String expiryDate;
  final int daysRemaining;
  final String expiryCategory;
  final String status;
  final String priority;
  final String assignedTo;
  final String vendor;
  final double estimatedCost;
  final String dueDate;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;

  const RenewalTaskModel({
    this.id,
    required this.certificateThumbprint,
    required this.certificateHolder,
    required this.expiryDate,
    required this.daysRemaining,
    required this.expiryCategory,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.vendor,
    required this.estimatedCost,
    required this.dueDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory RenewalTaskModel.fromMap(Map<String, dynamic> map) {
    return RenewalTaskModel(
      id: _toNullableInt(map['id']),
      certificateThumbprint: map['certificate_thumbprint']?.toString() ?? '',
      certificateHolder: map['certificate_holder']?.toString() ?? '',
      expiryDate: map['expiry_date']?.toString() ?? '',
      daysRemaining: _toInt(map['days_remaining']),
      expiryCategory: map['expiry_category']?.toString() ?? 'Unknown',
      status: map['status']?.toString() ?? 'New',
      priority: map['priority']?.toString() ?? 'Medium',
      assignedTo: map['assigned_to']?.toString() ?? '',
      vendor: map['vendor']?.toString() ?? '',
      estimatedCost: _toDouble(map['estimated_cost']),
      dueDate: map['due_date']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt:
          map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt:
          map['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      completedAt: map['completed_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'certificate_thumbprint': certificateThumbprint,
      'certificate_holder': certificateHolder,
      'expiry_date': expiryDate,
      'days_remaining': daysRemaining,
      'expiry_category': expiryCategory,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'vendor': vendor,
      'estimated_cost': estimatedCost,
      'due_date': dueDate,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'completed_at': completedAt,
    };
  }

  RenewalTaskModel copyWith({
    int? id,
    String? certificateThumbprint,
    String? certificateHolder,
    String? expiryDate,
    int? daysRemaining,
    String? expiryCategory,
    String? status,
    String? priority,
    String? assignedTo,
    String? vendor,
    double? estimatedCost,
    String? dueDate,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? completedAt,
    bool clearCompletedAt = false,
  }) {
    return RenewalTaskModel(
      id: id ?? this.id,
      certificateThumbprint:
          certificateThumbprint ?? this.certificateThumbprint,
      certificateHolder: certificateHolder ?? this.certificateHolder,
      expiryDate: expiryDate ?? this.expiryDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      expiryCategory: expiryCategory ?? this.expiryCategory,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      vendor: vendor ?? this.vendor,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
