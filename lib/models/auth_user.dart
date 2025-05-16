class AuthUser {
  final String id;
  final bool isMasterPasswordSet;
  final bool isBiometricsEnabled;
  final bool isGoogleAccountLinked;
  final DateTime lastLoginAt;

  AuthUser({
    required this.id,
    required this.isMasterPasswordSet,
    required this.isBiometricsEnabled,
    required this.isGoogleAccountLinked,
    required this.lastLoginAt,
  });

  AuthUser copyWith({
    String? id,
    bool? isMasterPasswordSet,
    bool? isBiometricsEnabled,
    bool? isGoogleAccountLinked,
    DateTime? lastLoginAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      isMasterPasswordSet: isMasterPasswordSet ?? this.isMasterPasswordSet,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isGoogleAccountLinked:
          isGoogleAccountLinked ?? this.isGoogleAccountLinked,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isMasterPasswordSet': isMasterPasswordSet,
      'isBiometricsEnabled': isBiometricsEnabled,
      'isGoogleAccountLinked': isGoogleAccountLinked,
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      isMasterPasswordSet: json['isMasterPasswordSet'] as bool,
      isBiometricsEnabled: json['isBiometricsEnabled'] as bool,
      isGoogleAccountLinked: json['isGoogleAccountLinked'] as bool,
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
    );
  }

  factory AuthUser.initial() {
    return AuthUser(
      id: 'user',
      isMasterPasswordSet: false,
      isBiometricsEnabled: false,
      isGoogleAccountLinked: false,
      lastLoginAt: DateTime.now(),
    );
  }
}
