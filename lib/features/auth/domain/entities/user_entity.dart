import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;
  final String? role;
  final String? phoneNumber;
  final String? address;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.role,
    this.phoneNumber,
    this.address,
  });

  @override
  List<Object?> get props =>
      [id, email, displayName, photoUrl, createdAt, role, phoneNumber, address];
}
