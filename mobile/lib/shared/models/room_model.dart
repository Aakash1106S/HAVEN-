import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@immutable
class RoomModel {
  final String id;
  final String homeId;
  final String name;
  final String icon;
  final int order;
  final DateTime createdAt;

  const RoomModel({
    required this.id,
    required this.homeId,
    required this.name,
    this.icon = 'living_room',
    this.order = 0,
    required this.createdAt,
  });

  static const List<String> roomIcons = [
    'living_room',
    'bedroom',
    'kitchen',
    'bathroom',
    'garage',
    'garden',
    'office',
    'dining_room',
    'hallway',
    'balcony',
  ];

  static const Map<String, int> iconCodepoints = {
    'living_room': 0xe395, // Icons.living
    'bedroom': 0xe0e3,     // Icons.bed
    'kitchen': 0xe359,     // Icons.kitchen
    'bathroom': 0xe0c8,    // Icons.bathtub
    'garage': 0xe2ba,      // Icons.garage
    'garden': 0xe707,      // Icons.yard
    'office': 0xe1c8,      // Icons.desk
    'dining_room': 0xe1ee, // Icons.dining
    'hallway': 0xe204,     // Icons.door_sliding
    'balcony': 0xe0cd,     // Icons.balcony
  };

  static IconData getIconData(String iconName) {
    final codePoint = iconCodepoints[iconName] ?? iconCodepoints['living_room']!;
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }

  IconData get iconData => getIconData(icon);

  RoomModel copyWith({
    String? id,
    String? homeId,
    String? name,
    String? icon,
    int? order,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RoomModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return RoomModel(
      id: id ?? json['id'] as String? ?? '',
      homeId: json['homeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'living_room',
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeId': homeId,
      'name': name,
      'icon': icon,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RoomModel(
      id: doc.id,
      homeId: data['homeId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      icon: data['icon'] as String? ?? 'living_room',
      order: (data['order'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'name': name,
      'icon': icon,
      'order': order,
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
      other is RoomModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          homeId == other.homeId &&
          name == other.name &&
          icon == other.icon &&
          order == other.order &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      homeId.hashCode ^
      name.hashCode ^
      icon.hashCode ^
      order.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'RoomModel(id: $id, homeId: $homeId, name: $name, '
        'icon: $icon, order: $order, createdAt: $createdAt)';
  }
}
