import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String userId;
  const ProfileLoadRequested(this.userId);
}

class ProfileUpdateRequested extends ProfileEvent {
  final String userId;
  final String? displayName;
  final String? phoneNumber;
  final String? address;

  const ProfileUpdateRequested({
    required this.userId,
    this.displayName,
    this.phoneNumber,
    this.address,
  });
}
