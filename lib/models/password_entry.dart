import 'package:uuid/uuid.dart';

class PasswordEntry {
  final String id;
  final String serviceName;
  final String password;
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordEntry({
    required this.id,
    required this.serviceName,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  PasswordEntry copyWith({
    String? id,
    String? serviceName,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      id: json['id'] as String,
      serviceName: json['serviceName'] as String,
      password: json['password'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
