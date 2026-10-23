import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? uid}) {
    return UserProfile(
      uid: uid ?? json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
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
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          emailVerified == other.emailVerified &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoUrl.hashCode ^
      emailVerified.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, displayName: $displayName, '
        'photoUrl: $photoUrl, emailVerified: $emailVerified, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
