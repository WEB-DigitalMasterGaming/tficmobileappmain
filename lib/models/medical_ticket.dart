import 'package:flutter/material.dart';

class MedicalTicket {
  final int id;
  final int userId;
  final String username;
  final bool isOrgMember;
  final String inGameUsername;
  final String currentSystem;
  final String currentLocation;
  final int? deathTimerRemaining;
  final String? notes;
  final String status; // Pending, InProgress, Completed, Cancelled, Archived
  final int? assignedMedicId;
  final String? assignedMedicUsername;
  final DateTime createdAt;
  final DateTime? claimedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  MedicalTicket({
    required this.id,
    required this.userId,
    required this.username,
    required this.isOrgMember,
    required this.inGameUsername,
    required this.currentSystem,
    required this.currentLocation,
    this.deathTimerRemaining,
    this.notes,
    required this.status,
    this.assignedMedicId,
    this.assignedMedicUsername,
    required this.createdAt,
    this.claimedAt,
    this.completedAt,
    required this.updatedAt,
  });

  factory MedicalTicket.fromJson(Map<String, dynamic> json) {
    return MedicalTicket(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      isOrgMember: json['isOrgMember'] ?? false,
      inGameUsername: json['inGameUsername'] ?? '',
      currentSystem: json['currentSystem'] ?? '',
      currentLocation: json['currentLocation'] ?? '',
      deathTimerRemaining: json['deathTimerRemaining'],
      notes: json['notes'],
      status: json['status'] ?? 'Pending',
      assignedMedicId: json['assignedMedicId'],
      assignedMedicUsername: json['assignedMedicUsername'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      claimedAt: json['claimedAt'] != null ? DateTime.parse(json['claimedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  String getStatusDisplay() {
    switch (status) {
      case 'Pending':
        return '⏳ Pending';
      case 'InProgress':
        return '🚑 In Progress';
      case 'Completed':
        return '✅ Completed';
      case 'Cancelled':
        return '❌ Cancelled';
      case 'Archived':
        return '📦 Archived';
      default:
        return status;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'Pending':
        return const Color(0xFFFFA500); // Orange
      case 'InProgress':
        return const Color(0xFF00BFFF); // Light blue
      case 'Completed':
        return const Color(0xFF00FF00); // Green
      case 'Cancelled':
        return const Color(0xFFFF0000); // Red
      case 'Archived':
        return const Color(0xFF808080); // Gray
      default:
        return const Color(0xFFFFFFFF); // White
    }
  }
}
