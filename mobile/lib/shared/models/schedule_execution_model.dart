import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class ScheduleExecutionModel {
  final String id;
  final String scheduleId;
  final String homeId;
  final DateTime scheduledAt;
  final DateTime? executedAt;
  final String status; // success, failed, skipped
  final String? commandId;
  final String? error;

  const ScheduleExecutionModel({
    required this.id,
    required this.scheduleId,
    required this.homeId,
    required this.scheduledAt,
    this.executedAt,
    required this.status,
    this.commandId,
    this.error,
  });

  ScheduleExecutionModel copyWith({
    String? id,
    String? scheduleId,
    String? homeId,
    DateTime? scheduledAt,
    DateTime? executedAt,
    String? status,
    String? commandId,
    String? error,
  }) {
    return ScheduleExecutionModel(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      homeId: homeId ?? this.homeId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      executedAt: executedAt ?? this.executedAt,
      status: status ?? this.status,
      commandId: commandId ?? this.commandId,
      error: error ?? this.error,
    );
  }

  factory ScheduleExecutionModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return ScheduleExecutionModel(
      id: id ?? json['id'] as String? ?? '',
      scheduleId: json['scheduleId'] as String? ?? '',
      homeId: json['homeId'] as String? ?? '',
      scheduledAt: _parseDateTime(json['scheduledAt']) ?? DateTime.now(),
      executedAt: _parseDateTime(json['executedAt']),
      status: json['status'] as String? ?? 'skipped',
      commandId: json['commandId'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'homeId': homeId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'executedAt': executedAt?.toIso8601String(),
      'status': status,
      'commandId': commandId,
      'error': error,
    };
  }

  factory ScheduleExecutionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ScheduleExecutionModel(
      id: doc.id,
      scheduleId: data['scheduleId'] as String? ?? '',
      homeId: data['homeId'] as String? ?? '',
      scheduledAt: _parseDateTime(data['scheduledAt']) ?? DateTime.now(),
      executedAt: _parseDateTime(data['executedAt']),
      status: data['status'] as String? ?? 'skipped',
      commandId: data['commandId'] as String?,
      error: data['error'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'scheduleId': scheduleId,
      'homeId': homeId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      if (executedAt != null) 'executedAt': Timestamp.fromDate(executedAt!),
      'status': status,
      'commandId': commandId,
      'error': error,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleExecutionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          scheduleId == other.scheduleId &&
          homeId == other.homeId &&
          scheduledAt == other.scheduledAt &&
          executedAt == other.executedAt &&
          status == other.status &&
          commandId == other.commandId &&
          error == other.error;

  @override
  int get hashCode =>
      id.hashCode ^
      scheduleId.hashCode ^
      homeId.hashCode ^
      scheduledAt.hashCode ^
      executedAt.hashCode ^
      status.hashCode ^
      commandId.hashCode ^
      error.hashCode;

  @override
  String toString() {
    return 'ScheduleExecutionModel(id: $id, scheduleId: $scheduleId, '
        'homeId: $homeId, scheduledAt: $scheduledAt, executedAt: $executedAt, '
        'status: $status, commandId: $commandId, error: $error)';
  }
}
