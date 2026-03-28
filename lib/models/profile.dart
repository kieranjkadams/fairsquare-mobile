import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.email,
    this.fullName,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'created_at': createdAt.toIso8601String(),
  };

  Profile copyWith({String? fullName, String? email}) {
    return Profile(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, createdAt];
}
