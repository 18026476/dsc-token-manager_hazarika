class ChangeModel {
  final String title;
  final String description;
  final String severity;
  final DateTime detectedAt;

  ChangeModel({
    required this.title,
    required this.description,
    required this.severity,
    required this.detectedAt,
  });
}
