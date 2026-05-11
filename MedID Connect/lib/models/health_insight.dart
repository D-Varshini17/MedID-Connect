class HealthInsight {
  const HealthInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.confidence,
    required this.category,
  });

  final String id;
  final String title;
  final String description;
  final String recommendation;
  final double confidence;
  final String category;
}
