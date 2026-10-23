import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'channel_model.dart';

@immutable
class CommandModel {
  final String id;
  final String homeId;
  final String channelId;
  final String deviceId;
  final String userId;
  final ApplianceState action;
  final CommandStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? dispatchedAt;
  final DateTime? acknowledgedAt;
  final DateTime? completedAt;
  final String correlationId;
  final String idempotencyKey;
  final String? errorMessage;

  const CommandModel({
    required this.id,
    required this.homeId,
    required this.channelId,
    required this.deviceId,
    required this.userId,
    required this.action,
    this.status = CommandStatus.queued,
    required this.createdAt,
    required this.expiresAt,
    this.dispatchedAt,
    this.acknowledgedAt,
    this.completedAt,
    required this.correlationId,
    required this.idempotencyKey,
    this.errorMessage,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  CommandModel copyWith({
    String? id,
    String? homeId,
    String? channelId,
    String? deviceId,
    String? userId,
    ApplianceState? action,
    CommandStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? dispatchedAt,
    DateTime? acknowledgedAt,
    DateTime? completedAt,
    String? correlationId,
    String? idempotencyKey,
    String? errorMessage,
  }) {
    return CommandModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      channelId: channelId ?? this.channelId,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      completedAt: completedAt ?? this.completedAt,
      correlationId: correlationId ?? this.correlationId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory CommandModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return CommandModel(
      id: id ?? json['id'] as String? ?? '',
      homeId: json['homeId'] as String? ?? '',
      channelId: json['channelId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      action: ApplianceState.fromString(json['action'] as String?),
      status: CommandStatus.fromString(
        json['status'] as String?,
        defaultValue: CommandStatus.queued,
      ),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      expiresAt: _parseDateTime(json['expiresAt']) ??
          DateTime.now().add(const Duration(seconds: 30)),
      dispatchedAt: _parseDateTime(json['dispatchedAt']),
      acknowledgedAt: _parseDateTime(json['acknowledgedAt']),
      completedAt: _parseDateTime(json['completedAt']),
      correlationId: json['correlationId'] as String? ?? '',
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeId': homeId,
      'channelId': channelId,
      'deviceId': deviceId,
      'userId': userId,
      'action': action.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'dispatchedAt': dispatchedAt?.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'correlationId': correlationId,
      'idempotencyKey': idempotencyKey,
      'errorMessage': errorMessage,
    };
  }

  factory CommandModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommandModel(
      id: doc.id,
      homeId: data['homeId'] as String? ?? '',
      channelId: data['channelId'] as String? ?? '',
      deviceId: data['deviceId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      action: ApplianceState.fromString(data['action'] as String?),
      status: CommandStatus.fromString(
        data['status'] as String?,
        defaultValue: CommandStatus.queued,
      ),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      expiresAt: _parseDateTime(data['expiresAt']) ??
          DateTime.now().add(const Duration(seconds: 30)),
      dispatchedAt: _parseDateTime(data['dispatchedAt']),
      acknowledgedAt: _parseDateTime(data['acknowledgedAt']),
      completedAt: _parseDateTime(data['completedAt']),
      correlationId: data['correlationId'] as String? ?? '',
      idempotencyKey: data['idempotencyKey'] as String? ?? '',
      errorMessage: data['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'channelId': channelId,
      'deviceId': deviceId,
      'userId': userId,
      'action': action.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      if (dispatchedAt != null) 'dispatchedAt': Timestamp.fromDate(dispatchedAt!),
      if (acknowledgedAt != null) 'acknowledgedAt': Timestamp.fromDate(acknowledgedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'correlationId': correlationId,
      'idempotencyKey': idempotencyKey,
      'errorMessage': errorMessage,
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
      other is CommandModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          homeId == other.homeId &&
          channelId == other.channelId &&
          deviceId == other.deviceId &&
          userId == other.userId &&
          action == other.action &&
          status == other.status &&
          createdAt == other.createdAt &&
          expiresAt == other.expiresAt &&
          dispatchedAt == other.dispatchedAt &&
          acknowledgedAt == other.acknowledgedAt &&
          completedAt == other.completedAt &&
          correlationId == other.correlationId &&
          idempotencyKey == other.idempotencyKey &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      id.hashCode ^
      homeId.hashCode ^
      channelId.hashCode ^
      deviceId.hashCode ^
      userId.hashCode ^
      action.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      expiresAt.hashCode ^
      dispatchedAt.hashCode ^
      acknowledgedAt.hashCode ^
      completedAt.hashCode ^
      correlationId.hashCode ^
      idempotencyKey.hashCode ^
      errorMessage.hashCode;

  @override
  String toString() {
    return 'CommandModel(id: $id, homeId: $homeId, channelId: $channelId, '
        'deviceId: $deviceId, userId: $userId, action: $action, '
        'status: $status, createdAt: $createdAt, expiresAt: $expiresAt, '
        'dispatchedAt: $dispatchedAt, acknowledgedAt: $acknowledgedAt, '
        'completedAt: $completedAt, correlationId: $correlationId, '
        'idempotencyKey: $idempotencyKey, errorMessage: $errorMessage)';
  }
}
