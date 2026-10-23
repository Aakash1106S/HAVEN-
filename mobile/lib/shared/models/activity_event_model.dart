import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ActivityEventType {
  deviceOnline,
  deviceOffline,
  commandSuccess,
  commandFailed,
  commandExpired,
  scheduleExecuted,
  scheduleFailed,
  applianceOn,
  applianceOff,
  devicePaired,
  deviceRemoved,
  userLoggedIn;

  static ActivityEventType fromString(
    String? value, {
    ActivityEventType defaultValue = ActivityEventType.deviceOnline,
  }) {
    if (value == null) return defaultValue;
    return ActivityEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => defaultValue,
    );
  }
}

@immutable
class ActivityEventModel {
  final String id;
  final String homeId;
  final ActivityEventType type;
  final String title;
  final String message;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final bool read;

  const ActivityEventModel({
    required this.id,
    required this.homeId,
    required this.type,
    required this.title,
    required this.message,
    this.metadata = const {},
    required this.createdAt,
    this.read = false,
  });

  IconData get icon {
    switch (type) {
      case ActivityEventType.deviceOnline:
        return Icons.wifi;
      case ActivityEventType.deviceOffline:
        return Icons.wifi_off;
      case ActivityEventType.commandSuccess:
        return Icons.check_circle_outline;
      case ActivityEventType.commandFailed:
        return Icons.error_outline;
      case ActivityEventType.commandExpired:
        return Icons.timer_off_outlined;
      case ActivityEventType.scheduleExecuted:
        return Icons.schedule;
      case ActivityEventType.scheduleFailed:
        return Icons.event_busy;
      case ActivityEventType.applianceOn:
        return Icons.power;
      case ActivityEventType.applianceOff:
        return Icons.power_off;
      case ActivityEventType.devicePaired:
        return Icons.link;
      case ActivityEventType.deviceRemoved:
        return Icons.link_off;
      case ActivityEventType.userLoggedIn:
        return Icons.login;
    }
  }

  Color get color {
    switch (type) {
      case ActivityEventType.deviceOnline:
      case ActivityEventType.commandSuccess:
      case ActivityEventType.devicePaired:
        return const Color(0xFF10B981);
      case ActivityEventType.applianceOn:
        return const Color(0xFF06B6D4);
      case ActivityEventType.deviceOffline:
      case ActivityEventType.commandFailed:
      case ActivityEventType.scheduleFailed:
      case ActivityEventType.deviceRemoved:
        return const Color(0xFFEF4444);
      case ActivityEventType.commandExpired:
        return const Color(0xFFF59E0B);
      case ActivityEventType.scheduleExecuted:
      case ActivityEventType.userLoggedIn:
        return const Color(0xFF3B82F6);
      case ActivityEventType.applianceOff:
        return const Color(0xFF6B7280);
    }
  }

  ActivityEventModel copyWith({
    String? id,
    String? homeId,
    ActivityEventType? type,
    String? title,
    String? message,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? read,
  }) {
    return ActivityEventModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
    );
  }

  factory ActivityEventModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final rawMetadata = json['metadata'];
    final meta = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : const <String, dynamic>{};

    return ActivityEventModel(
      id: id ?? json['id'] as String? ?? '',
      homeId: json['homeId'] as String? ?? '',
      type: ActivityEventType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      metadata: meta,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeId': homeId,
      'type': type.name,
      'title': title,
      'message': message,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
    };
  }

  factory ActivityEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawMetadata = data['metadata'];
    final meta = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : const <String, dynamic>{};

    return ActivityEventModel(
      id: doc.id,
      homeId: data['homeId'] as String? ?? '',
      type: ActivityEventType.fromString(data['type'] as String?),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      metadata: meta,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'type': type.name,
      'title': title,
      'message': message,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
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
      other is ActivityEventModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          homeId == other.homeId &&
          type == other.type &&
          title == other.title &&
          message == other.message &&
          mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          read == other.read;

  @override
  int get hashCode =>
      id.hashCode ^
      homeId.hashCode ^
      type.hashCode ^
      title.hashCode ^
      message.hashCode ^
      Object.hashAll(metadata.entries) ^
      createdAt.hashCode ^
      read.hashCode;

  @override
  String toString() {
    return 'ActivityEventModel(id: $id, homeId: $homeId, type: $type, '
        'title: $title, message: $message, metadata: $metadata, '
        'createdAt: $createdAt, read: $read)';
  }
}
