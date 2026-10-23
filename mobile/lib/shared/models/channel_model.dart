import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ApplianceState {
  on,
  off;

  static ApplianceState fromString(
    String? value, {
    ApplianceState defaultValue = ApplianceState.off,
  }) {
    if (value == null) return defaultValue;
    return ApplianceState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => defaultValue,
    );
  }

  bool get isOn => this == ApplianceState.on;
  bool get isOff => this == ApplianceState.off;
}

enum CommandStatus {
  idle,
  queued,
  dispatched,
  acknowledged,
  succeeded,
  failed,
  expired;

  static CommandStatus fromString(
    String? value, {
    CommandStatus defaultValue = CommandStatus.idle,
  }) {
    if (value == null) return defaultValue;
    return CommandStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => defaultValue,
    );
  }

  bool get isPending =>
      this == CommandStatus.queued ||
      this == CommandStatus.dispatched ||
      this == CommandStatus.acknowledged;
}

@immutable
class ChannelModel {
  final String id;
  final String homeId;
  final String deviceId;
  final String? roomId;
  final int channelNumber;
  final String applianceName;
  final ApplianceState desiredState;
  final ApplianceState reportedState;
  final CommandStatus commandStatus;
  final String? lastCommandId;
  final DateTime? lastCommandAt;
  final DateTime? lastReportedAt;
  final DateTime createdAt;

  const ChannelModel({
    required this.id,
    required this.homeId,
    required this.deviceId,
    this.roomId,
    required this.channelNumber,
    required this.applianceName,
    this.desiredState = ApplianceState.off,
    this.reportedState = ApplianceState.off,
    this.commandStatus = CommandStatus.idle,
    this.lastCommandId,
    this.lastCommandAt,
    this.lastReportedAt,
    required this.createdAt,
  });

  bool get isPending => commandStatus.isPending;

  bool get isStale => desiredState != reportedState;

  bool get isOn => reportedState == ApplianceState.on;

  bool get isOff => reportedState == ApplianceState.off;

  String get displayStatus {
    switch (commandStatus) {
      case CommandStatus.queued:
        return 'Queued';
      case CommandStatus.dispatched:
        return 'Sending...';
      case CommandStatus.acknowledged:
        return 'Applying...';
      case CommandStatus.failed:
        return 'Failed';
      case CommandStatus.expired:
        return 'Timeout';
      case CommandStatus.succeeded:
      case CommandStatus.idle:
        if (isStale) return 'Syncing...';
        return reportedState == ApplianceState.on ? 'On' : 'Off';
    }
  }

  ChannelModel copyWith({
    String? id,
    String? homeId,
    String? deviceId,
    String? roomId,
    int? channelNumber,
    String? applianceName,
    ApplianceState? desiredState,
    ApplianceState? reportedState,
    CommandStatus? commandStatus,
    String? lastCommandId,
    DateTime? lastCommandAt,
    DateTime? lastReportedAt,
    DateTime? createdAt,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      deviceId: deviceId ?? this.deviceId,
      roomId: roomId ?? this.roomId,
      channelNumber: channelNumber ?? this.channelNumber,
      applianceName: applianceName ?? this.applianceName,
      desiredState: desiredState ?? this.desiredState,
      reportedState: reportedState ?? this.reportedState,
      commandStatus: commandStatus ?? this.commandStatus,
      lastCommandId: lastCommandId ?? this.lastCommandId,
      lastCommandAt: lastCommandAt ?? this.lastCommandAt,
      lastReportedAt: lastReportedAt ?? this.lastReportedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChannelModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return ChannelModel(
      id: id ?? json['id'] as String? ?? '',
      homeId: json['homeId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      roomId: json['roomId'] as String?,
      channelNumber: (json['channelNumber'] as num?)?.toInt() ?? 0,
      applianceName: json['applianceName'] as String? ?? '',
      desiredState: ApplianceState.fromString(json['desiredState'] as String?),
      reportedState: ApplianceState.fromString(json['reportedState'] as String?),
      commandStatus: CommandStatus.fromString(json['commandStatus'] as String?),
      lastCommandId: json['lastCommandId'] as String?,
      lastCommandAt: _parseDateTime(json['lastCommandAt']),
      lastReportedAt: _parseDateTime(json['lastReportedAt']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeId': homeId,
      'deviceId': deviceId,
      'roomId': roomId,
      'channelNumber': channelNumber,
      'applianceName': applianceName,
      'desiredState': desiredState.name,
      'reportedState': reportedState.name,
      'commandStatus': commandStatus.name,
      'lastCommandId': lastCommandId,
      'lastCommandAt': lastCommandAt?.toIso8601String(),
      'lastReportedAt': lastReportedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChannelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChannelModel(
      id: doc.id,
      homeId: data['homeId'] as String? ?? '',
      deviceId: data['deviceId'] as String? ?? '',
      roomId: data['roomId'] as String?,
      channelNumber: (data['channelNumber'] as num?)?.toInt() ?? 0,
      applianceName: data['applianceName'] as String? ?? '',
      desiredState: ApplianceState.fromString(data['desiredState'] as String?),
      reportedState: ApplianceState.fromString(data['reportedState'] as String?),
      commandStatus: CommandStatus.fromString(data['commandStatus'] as String?),
      lastCommandId: data['lastCommandId'] as String?,
      lastCommandAt: _parseDateTime(data['lastCommandAt']),
      lastReportedAt: _parseDateTime(data['lastReportedAt']),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'deviceId': deviceId,
      'roomId': roomId,
      'channelNumber': channelNumber,
      'applianceName': applianceName,
      'desiredState': desiredState.name,
      'reportedState': reportedState.name,
      'commandStatus': commandStatus.name,
      'lastCommandId': lastCommandId,
      if (lastCommandAt != null) 'lastCommandAt': Timestamp.fromDate(lastCommandAt!),
      if (lastReportedAt != null) 'lastReportedAt': Timestamp.fromDate(lastReportedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
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
      other is ChannelModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          homeId == other.homeId &&
          deviceId == other.deviceId &&
          roomId == other.roomId &&
          channelNumber == other.channelNumber &&
          applianceName == other.applianceName &&
          desiredState == other.desiredState &&
          reportedState == other.reportedState &&
          commandStatus == other.commandStatus &&
          lastCommandId == other.lastCommandId &&
          lastCommandAt == other.lastCommandAt &&
          lastReportedAt == other.lastReportedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      homeId.hashCode ^
      deviceId.hashCode ^
      roomId.hashCode ^
      channelNumber.hashCode ^
      applianceName.hashCode ^
      desiredState.hashCode ^
      reportedState.hashCode ^
      commandStatus.hashCode ^
      lastCommandId.hashCode ^
      lastCommandAt.hashCode ^
      lastReportedAt.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'ChannelModel(id: $id, homeId: $homeId, deviceId: $deviceId, '
        'roomId: $roomId, channelNumber: $channelNumber, '
        'applianceName: $applianceName, desiredState: $desiredState, '
        'reportedState: $reportedState, commandStatus: $commandStatus, '
        'lastCommandId: $lastCommandId, lastCommandAt: $lastCommandAt, '
        'lastReportedAt: $lastReportedAt, createdAt: $createdAt)';
  }
}
