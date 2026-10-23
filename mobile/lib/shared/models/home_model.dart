import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class HomeModel {
  final String id;
  final String name;
  final String timezone;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const HomeModel({
    required this.id,
    required this.name,
    required this.timezone,
    required this.ownerId,
    this.memberIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  HomeModel copyWith({
    String? id,
    String? name,
    String? timezone,
    String? ownerId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      timezone: timezone ?? this.timezone,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory HomeModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final rawMembers = json['memberIds'];
    final members = rawMembers is List
        ? rawMembers.map((e) => e.toString()).toList()
        : <String>[];

    return HomeModel(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'UTC',
      ownerId: json['ownerId'] as String? ?? '',
      memberIds: members,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timezone': timezone,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory HomeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawMembers = data['memberIds'];
    final members = rawMembers is List
        ? rawMembers.map((e) => e.toString()).toList()
        : <String>[];

    return HomeModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      timezone: data['timezone'] as String? ?? 'UTC',
      ownerId: data['ownerId'] as String? ?? '',
      memberIds: members,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'timezone': timezone,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
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
      other is HomeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          timezone == other.timezone &&
          ownerId == other.ownerId &&
          listEquals(memberIds, other.memberIds) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      timezone.hashCode ^
      ownerId.hashCode ^
      Object.hashAll(memberIds) ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'HomeModel(id: $id, name: $name, timezone: $timezone, '
        'ownerId: $ownerId, memberIds: $memberIds, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
