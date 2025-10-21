class Recommendation {
  final String locationName;
  final double latitude;
  final double longitude;
  final double score;
  final Map<String, double> factors;
  final String description;
  final String type;
  final String title;
  final List<String> details;

  Recommendation({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.score,
    required this.factors,
    required this.description,
    this.type = 'general',
    this.title = '',
    this.details = const [],
  });

  factory Recommendation.fromMap(Map<String, dynamic> map) {
    return Recommendation(
      locationName: map['locationName'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      score: (map['score'] ?? 0.0).toDouble(),
      factors: Map<String, double>.from(map['factors'] ?? {}),
      description: map['description'] ?? '',
      type: map['type'] ?? 'general',
      title: map['title'] ?? '',
      details: List<String>.from(map['details'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'score': score,
      'factors': factors,
      'description': description,
      'type': type,
      'title': title,
      'details': details,
    };
  }
}
