class Mission {
  final int id;
  final String title;
  final String objective;
  final String? briefing;
  final String status;
  final String? createdBy;
  final int? createdByOrgPoints;
  final String? missionType;
  final int? completionTimeLimit;
  final DateTime? startAt;
  final DateTime? endAt;
  final int? maxParticipants;
  final int? rewardPoints;
  final int? bonusPoints;

  Mission({
    required this.id,
    required this.title,
    required this.objective,
    this.briefing,
    required this.status,
    this.createdBy,
    this.createdByOrgPoints,
    this.missionType,
    this.completionTimeLimit,
    this.startAt,
    this.endAt,
    this.maxParticipants,
    this.rewardPoints,
    this.bonusPoints,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      objective: json['objective'] ?? '',
      briefing: json['briefing'],
      status: json['status'] ?? 'Open',
      createdBy: json['createdBy'],
      createdByOrgPoints: json['createdByOrgPoints'],
      missionType: json['missionType'],
      completionTimeLimit: json['completionTimeLimit'],
      startAt: json['startAt'] != null ? DateTime.parse(json['startAt']) : null,
      endAt: json['endAt'] != null ? DateTime.parse(json['endAt']) : null,
      maxParticipants: json['maxParticipants'],
      rewardPoints: json['rewardPoints'],
      bonusPoints: json['bonusPoints'],
    );
  }
}

class MissionAcceptance {
  final int id;
  final int missionId;
  final String missionTitle;
  final String missionObjective;
  final String? missionBriefing;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final int? rewardPoints;
  final int? bonusPoints;

  MissionAcceptance({
    required this.id,
    required this.missionId,
    required this.missionTitle,
    required this.missionObjective,
    this.missionBriefing,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.rewardPoints,
    this.bonusPoints,
  });

  factory MissionAcceptance.fromJson(Map<String, dynamic> json) {
    return MissionAcceptance(
      id: json['id'] ?? 0,
      missionId: json['missionId'] ?? 0,
      missionTitle: json['missionTitle'] ?? '',
      missionObjective: json['missionObjective'] ?? '',
      missionBriefing: json['missionBriefing'],
      status: json['status'] ?? 'Accepted',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
      rewardPoints: json['rewardPoints'],
      bonusPoints: json['bonusPoints'],
    );
  }
}
