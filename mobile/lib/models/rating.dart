class Rating {
  final int id;
  final int? userId;
  final int? driverId;
  final String? routeId;
  final int? tripId;
  final int? companyId;
  final int rating; // 1-5
  final String? comment;
  final int? punctualityRating;
  final int? serviceRating;
  final int? cleanlinessRating;
  final int? safetyRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rating({
    required this.id,
    this.userId,
    this.driverId,
    this.routeId,
    this.tripId,
    this.companyId,
    required this.rating,
    this.comment,
    this.punctualityRating,
    this.serviceRating,
    this.cleanlinessRating,
    this.safetyRating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      driverId: json['driver_id'],
      routeId: json['route_id'],
      tripId: json['trip_id'],
      companyId: json['company_id'],
      rating: json['rating'] ?? 5,
      comment: json['comment'],
      punctualityRating: json['punctuality_rating'],
      serviceRating: json['service_rating'],
      cleanlinessRating: json['cleanliness_rating'],
      safetyRating: json['safety_rating'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'driver_id': driverId,
      'route_id': routeId,
      'trip_id': tripId,
      'company_id': companyId,
      'rating': rating,
      'comment': comment,
      'punctuality_rating': punctualityRating,
      'service_rating': serviceRating,
      'cleanliness_rating': cleanlinessRating,
      'safety_rating': safetyRating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

