class Feedback {
  final int id;
  final int userId;
  final String userName;
  final String? userEmail;
  final String pageScope;
  final String category;
  final String message;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FeedbackResponse> responses;

  Feedback({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail,
    required this.pageScope,
    required this.category,
    required this.message,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.responses = const [],
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'],
      pageScope: json['pageScope'] ?? '',
      category: json['category'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Open',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      responses: (json['responses'] as List<dynamic>?)
              ?.map((r) => FeedbackResponse.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class FeedbackResponse {
  final int id;
  final int adminUserId;
  final String adminName;
  final String responseText;
  final DateTime respondedAt;

  FeedbackResponse({
    required this.id,
    required this.adminUserId,
    required this.adminName,
    required this.responseText,
    required this.respondedAt,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      id: json['id'] ?? 0,
      adminUserId: json['adminUserId'] ?? 0,
      adminName: json['adminName'] ?? '',
      responseText: json['responseText'] ?? '',
      respondedAt: DateTime.parse(json['respondedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
