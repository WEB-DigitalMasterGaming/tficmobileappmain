class TicketMessage {
  final int id;
  final int ticketId;
  final int userId;
  final String username;
  final String message;
  final DateTime createdAt;
  final bool isSystemMessage;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.username,
    required this.message,
    required this.createdAt,
    this.isSystemMessage = false,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? 0,
      ticketId: json['ticketId'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      isSystemMessage: json['isSystemMessage'] ?? false,
    );
  }
}
