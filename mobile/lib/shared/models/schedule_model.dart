import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'channel_model.dart';

@immutable
class ScheduleModel {
  final String id;
  final String homeId;
  final String channelId;
  final String deviceId;
  final String applianceName;
  final ApplianceState action;
  final String cronExpression;
  final String timezone;
  final bool isEnabled;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final String? lastStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleModel({
    required this.id,
    required this.homeId,
    required this.channelId,
    required this.deviceId,
    required this.applianceName,
    required this.action,
    required this.cronExpression,
    required this.timezone,
    this.isEnabled = true,
    this.startDate,
    this.endDate,
    this.nextRunAt,
    this.lastRunAt,
    this.lastStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleModel.create({
    required String homeId,
    required String channelId,
    required String deviceId,
    required String applianceName,
    required ApplianceState action,
    required String cronExpression,
    required String timezone,
    bool isEnabled = true,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    String? lastStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return ScheduleModel(
      id: const Uuid().v4(),
      homeId: homeId,
      channelId: channelId,
      deviceId: deviceId,
      applianceName: applianceName,
      action: action,
      cronExpression: cronExpression,
      timezone: timezone,
      isEnabled: isEnabled,
      startDate: startDate,
      endDate: endDate,
      nextRunAt: nextRunAt,
      lastRunAt: lastRunAt,
      lastStatus: lastStatus,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  ScheduleModel copyWith({
    String? id,
    String? homeId,
    String? channelId,
    String? deviceId,
    String? applianceName,
    ApplianceState? action,
    String? cronExpression,
    String? timezone,
    bool? isEnabled,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    String? lastStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      channelId: channelId ?? this.channelId,
      deviceId: deviceId ?? this.deviceId,
      applianceName: applianceName ?? this.applianceName,
      action: action ?? this.action,
      cronExpression: cronExpression ?? this.cronExpression,
      timezone: timezone ?? this.timezone,
      isEnabled: isEnabled ?? this.isEnabled,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      lastStatus: lastStatus ?? this.lastStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return ScheduleModel(
      id: id ?? json['id'] as String? ?? '',
      homeId: json['homeId'] as String? ?? '',
      channelId: json['channelId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      applianceName: json['applianceName'] as String? ?? '',
      action: ApplianceState.fromString(json['action'] as String?),
      cronExpression: json['cronExpression'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'UTC',
      isEnabled: json['isEnabled'] as bool? ?? true,
      startDate: _parseDateTime(json['startDate']),
      endDate: _parseDateTime(json['endDate']),
      nextRunAt: _parseDateTime(json['nextRunAt']),
      lastRunAt: _parseDateTime(json['lastRunAt']),
      lastStatus: json['lastStatus'] as String?,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeId': homeId,
      'channelId': channelId,
      'deviceId': deviceId,
      'applianceName': applianceName,
      'action': action.name,
      'cronExpression': cronExpression,
      'timezone': timezone,
      'isEnabled': isEnabled,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextRunAt': nextRunAt?.toIso8601String(),
      'lastRunAt': lastRunAt?.toIso8601String(),
      'lastStatus': lastStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ScheduleModel(
      id: doc.id,
      homeId: data['homeId'] as String? ?? '',
      channelId: data['channelId'] as String? ?? '',
      deviceId: data['deviceId'] as String? ?? '',
      applianceName: data['applianceName'] as String? ?? '',
      action: ApplianceState.fromString(data['action'] as String?),
      cronExpression: data['cronExpression'] as String? ?? '',
      timezone: data['timezone'] as String? ?? 'UTC',
      isEnabled: data['isEnabled'] as bool? ?? true,
      startDate: _parseDateTime(data['startDate']),
      endDate: _parseDateTime(data['endDate']),
      nextRunAt: _parseDateTime(data['nextRunAt']),
      lastRunAt: _parseDateTime(data['lastRunAt']),
      lastStatus: data['lastStatus'] as String?,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'channelId': channelId,
      'deviceId': deviceId,
      'applianceName': applianceName,
      'action': action.name,
      'cronExpression': cronExpression,
      'timezone': timezone,
      'isEnabled': isEnabled,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (nextRunAt != null) 'nextRunAt': Timestamp.fromDate(nextRunAt!),
      if (lastRunAt != null) 'lastRunAt': Timestamp.fromDate(lastRunAt!),
      'lastStatus': lastStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
      other is ScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          homeId == other.homeId &&
          channelId == other.channelId &&
          deviceId == other.deviceId &&
          applianceName == other.applianceName &&
          action == other.action &&
          cronExpression == other.cronExpression &&
          timezone == other.timezone &&
          isEnabled == other.isEnabled &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          nextRunAt == other.nextRunAt &&
          lastRunAt == other.lastRunAt &&
          lastStatus == other.lastStatus &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      homeId.hashCode ^
      channelId.hashCode ^
      deviceId.hashCode ^
      applianceName.hashCode ^
      action.hashCode ^
      cronExpression.hashCode ^
      timezone.hashCode ^
      isEnabled.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      nextRunAt.hashCode ^
      lastRunAt.hashCode ^
      lastStatus.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'ScheduleModel(id: $id, homeId: $homeId, channelId: $channelId, '
        'deviceId: $deviceId, applianceName: $applianceName, action: $action, '
        'cronExpression: $cronExpression, timezone: $timezone, '
        'isEnabled: $isEnabled, startDate: $startDate, endDate: $endDate, '
        'nextRunAt: $nextRunAt, lastRunAt: $lastRunAt, lastStatus: $lastStatus, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
