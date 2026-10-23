/// User domain model for Haven Smart Home
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final bool hasHome;
  final bool isEmailVerified;
  final String? photoUrl;
  final String? activeHomeId;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.hasHome = false,
    this.isEmailVerified = false,
    this.photoUrl,
    this.activeHomeId,
    this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? hasHome,
    bool? isEmailVerified,
    String? photoUrl,
    String? activeHomeId,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      hasHome: hasHome ?? this.hasHome,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      activeHomeId: activeHomeId ?? this.activeHomeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'hasHome': hasHome,
      'isEmailVerified': isEmailVerified,
      'photoUrl': photoUrl,
      'activeHomeId': activeHomeId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserModel(
      uid: uid ?? map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      hasHome: map['hasHome'] as bool? ?? false,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      photoUrl: map['photoUrl'] as String?,
      activeHomeId: map['activeHomeId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          hasHome == other.hasHome &&
          isEmailVerified == other.isEmailVerified &&
          activeHomeId == other.activeHomeId;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      hasHome.hashCode ^
      isEmailVerified.hashCode ^
      activeHomeId.hashCode;
}
