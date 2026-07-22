class DepartmentModel {
  final int? id;
  final String name;
  final String description;

  DepartmentModel({this.id, required this.name, required this.description});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
    );
  }
}
