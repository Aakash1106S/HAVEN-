import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum DeviceStatus {
  online,
  offline,
  unknown;

  static DeviceStatus fromString(String? value) {
    if (value == null) return DeviceStatus.unknown;
    return DeviceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeviceStatus.unknown,
    );
  }
}

@immutable
class DeviceModel {
  final String id;
  final String homeId;
  final String name;
  final String? firmwareVersion;
  final DateTime? lastSeenAt;
  final DeviceStatus status;
  final String ownerId;
  final int channelCount;
  final int? wifiRssi;
  final DateTime createdAt;

  const DeviceModel({
    required this.id,
    required this.homeId,
    required this.name,
    this.firmwareVersion,
    this.lastSeenAt,
    this.status = DeviceStatus.unknown,
    required this.ownerId,
    this.channelCount = 3,
    this.wifiRssi,
    required this.createdAt,
  });

  bool get isOnline => status == DeviceStatus.online;

  DeviceModel copyWith({
    String? id,
    String? homeId,
    String? name,
    String? firmwareVersion,
    DateTime? lastSeenAt,
    DeviceStatus? status,
    String? ownerId,
    int? channelCount,
    int? wifiRssi,
    DateTime? createdAt,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      channelCount: channelCount ?? this.channelCount,
      wifiRssi: wifiRssi ?? this.wifiRssi,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return DeviceModel(
      id: id ?? json['id'] as String? ?? '',
      homeId: json['homeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      firmwareVersion: json['firmwareVersion'] as String?,
      lastSeenAt: _parseDateTime(json['lastSeenAt']),
      status: DeviceStatus.fromString(json['status'] as String?),
      ownerId: json['ownerId'] as String? ?? '',
      channelCount: (json['channelCount'] as num?)?.toInt() ?? 3,
      wifiRssi: (json['wifiRssi'] as num?)?.toInt(),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeId': homeId,
      'name': name,
      'firmwareVersion': firmwareVersion,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'status': status.name,
      'ownerId': ownerId,
      'channelCount': channelCount,
      'wifiRssi': wifiRssi,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DeviceModel(
      id: doc.id,
      homeId: data['homeId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      firmwareVersion: data['firmwareVersion'] as String?,
      lastSeenAt: _parseDateTime(data['lastSeenAt']),
      status: DeviceStatus.fromString(data['status'] as String?),
      ownerId: data['ownerId'] as String? ?? '',
      channelCount: (data['channelCount'] as num?)?.toInt() ?? 3,
      wifiRssi: (data['wifiRssi'] as num?)?.toInt(),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'name': name,
      'firmwareVersion': firmwareVersion,
      if (lastSeenAt != null) 'lastSeenAt': Timestamp.fromDate(lastSeenAt!),
      'status': status.name,
      'ownerId': ownerId,
      'channelCount': channelCount,
      'wifiRssi': wifiRssi,
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
      other is DeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          homeId == other.homeId &&
          name == other.name &&
          firmwareVersion == other.firmwareVersion &&
          lastSeenAt == other.lastSeenAt &&
          status == other.status &&
          ownerId == other.ownerId &&
          channelCount == other.channelCount &&
          wifiRssi == other.wifiRssi &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      homeId.hashCode ^
      name.hashCode ^
      firmwareVersion.hashCode ^
      lastSeenAt.hashCode ^
      status.hashCode ^
      ownerId.hashCode ^
      channelCount.hashCode ^
      wifiRssi.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'DeviceModel(id: $id, homeId: $homeId, name: $name, '
        'firmwareVersion: $firmwareVersion, lastSeenAt: $lastSeenAt, '
        'status: $status, ownerId: $ownerId, channelCount: $channelCount, '
        'wifiRssi: $wifiRssi, createdAt: $createdAt)';
  }
}
