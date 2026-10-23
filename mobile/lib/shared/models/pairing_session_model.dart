import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class PairingSessionModel {
  final String id;
  final String homeId;
  final String userId;
  final String pairingCode; // 6-char alphanumeric
  final String status;      // pending, completed, expired
  final String? deviceId;
  final DateTime expiresAt;
  final DateTime createdAt;

  const PairingSessionModel({
    required this.id,
    required this.homeId,
    required this.userId,
    required this.pairingCode,
    this.status = 'pending',
    this.deviceId,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending' && !isExpired;

  PairingSessionModel copyWith({
    String? id,
    String? homeId,
    String? userId,
    String? pairingCode,
    String? status,
    String? deviceId,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return PairingSessionModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      userId: userId ?? this.userId,
      pairingCode: pairingCode ?? this.pairingCode,
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PairingSessionModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return PairingSessionModel(
      id: id ?? json['id'] as String? ?? '',
      homeId: json['homeId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      pairingCode: json['pairingCode'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      deviceId: json['deviceId'] as String?,
      expiresAt: _parseDateTime(json['expiresAt']) ?? DateTime.now(),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeId': homeId,
      'userId': userId,
      'pairingCode': pairingCode,
      'status': status,
      'deviceId': deviceId,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PairingSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PairingSessionModel(
      id: doc.id,
      homeId: data['homeId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      pairingCode: data['pairingCode'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      deviceId: data['deviceId'] as String?,
      expiresAt: _parseDateTime(data['expiresAt']) ?? DateTime.now(),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'userId': userId,
      'pairingCode': pairingCode,
      'status': status,
      'deviceId': deviceId,
      'expiresAt': Timestamp.fromDate(expiresAt),
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
      other is PairingSessionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          homeId == other.homeId &&
          userId == other.userId &&
          pairingCode == other.pairingCode &&
          status == other.status &&
          deviceId == other.deviceId &&
          expiresAt == other.expiresAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      homeId.hashCode ^
      userId.hashCode ^
      pairingCode.hashCode ^
      status.hashCode ^
      deviceId.hashCode ^
      expiresAt.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'PairingSessionModel(id: $id, homeId: $homeId, userId: $userId, '
        'pairingCode: $pairingCode, status: $status, deviceId: $deviceId, '
        'expiresAt: $expiresAt, createdAt: $createdAt)';
  }
}
