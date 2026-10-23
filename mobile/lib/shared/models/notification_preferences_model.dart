import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class NotificationPreferencesModel {
  final String userId;
  final bool deviceOffline;
  final bool commandFailure;
  final bool scheduleExecution;
  final bool deviceReconnect;
  final String? fcmToken;
  final DateTime? updatedAt;

  const NotificationPreferencesModel({
    required this.userId,
    this.deviceOffline = true,
    this.commandFailure = true,
    this.scheduleExecution = false,
    this.deviceReconnect = false,
    this.fcmToken,
    this.updatedAt,
  });

  NotificationPreferencesModel copyWith({
    String? userId,
    bool? deviceOffline,
    bool? commandFailure,
    bool? scheduleExecution,
    bool? deviceReconnect,
    String? fcmToken,
    DateTime? updatedAt,
  }) {
    return NotificationPreferencesModel(
      userId: userId ?? this.userId,
      deviceOffline: deviceOffline ?? this.deviceOffline,
      commandFailure: commandFailure ?? this.commandFailure,
      scheduleExecution: scheduleExecution ?? this.scheduleExecution,
      deviceReconnect: deviceReconnect ?? this.deviceReconnect,
      fcmToken: fcmToken ?? this.fcmToken,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json, {String? userId}) {
    return NotificationPreferencesModel(
      userId: userId ?? json['userId'] as String? ?? '',
      deviceOffline: json['deviceOffline'] as bool? ?? true,
      commandFailure: json['commandFailure'] as bool? ?? true,
      scheduleExecution: json['scheduleExecution'] as bool? ?? false,
      deviceReconnect: json['deviceReconnect'] as bool? ?? false,
      fcmToken: json['fcmToken'] as String?,
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deviceOffline': deviceOffline,
      'commandFailure': commandFailure,
      'scheduleExecution': scheduleExecution,
      'deviceReconnect': deviceReconnect,
      'fcmToken': fcmToken,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory NotificationPreferencesModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationPreferencesModel(
      userId: (data['userId'] as String?)?.isNotEmpty == true ? data['userId'] as String : doc.id,
      deviceOffline: data['deviceOffline'] as bool? ?? true,
      commandFailure: data['commandFailure'] as bool? ?? true,
      scheduleExecution: data['scheduleExecution'] as bool? ?? false,
      deviceReconnect: data['deviceReconnect'] as bool? ?? false,
      fcmToken: data['fcmToken'] as String?,
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'deviceOffline': deviceOffline,
      'commandFailure': commandFailure,
      'scheduleExecution': scheduleExecution,
      'deviceReconnect': deviceReconnect,
      'fcmToken': fcmToken,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
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
      other is NotificationPreferencesModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          deviceOffline == other.deviceOffline &&
          commandFailure == other.commandFailure &&
          scheduleExecution == other.scheduleExecution &&
          deviceReconnect == other.deviceReconnect &&
          fcmToken == other.fcmToken &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      userId.hashCode ^
      deviceOffline.hashCode ^
      commandFailure.hashCode ^
      scheduleExecution.hashCode ^
      deviceReconnect.hashCode ^
      fcmToken.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'NotificationPreferencesModel(userId: $userId, '
        'deviceOffline: $deviceOffline, commandFailure: $commandFailure, '
        'scheduleExecution: $scheduleExecution, '
        'deviceReconnect: $deviceReconnect, fcmToken: $fcmToken, '
        'updatedAt: $updatedAt)';
  }
}
