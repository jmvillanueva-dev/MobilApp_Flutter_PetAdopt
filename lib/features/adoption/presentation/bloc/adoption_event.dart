import 'package:equatable/equatable.dart';

sealed class AdoptionEvent extends Equatable {
  const AdoptionEvent();

  @override
  List<Object?> get props => [];
}

class CreateAdoptonRequest extends AdoptionEvent {
  final String petId;
  final String shelterId;
  final String? message;

  const CreateAdoptonRequest({
    required this.petId,
    required this.shelterId,
    this.message,
  });

  @override
  List<Object?> get props => [petId, shelterId, message];
}

class LoadAdopterRequests extends AdoptionEvent {}

class LoadShelterRequests extends AdoptionEvent {}

class UpdateRequestStatus extends AdoptionEvent {
  final String requestId;
  final String status;

  const UpdateRequestStatus({
    required this.requestId,
    required this.status,
  });

  @override
  List<Object?> get props => [requestId, status];
}

class DeleteAdoptionRequest extends AdoptionEvent {
  final String requestId;

  const DeleteAdoptionRequest(this.requestId);

  @override
  List<Object?> get props => [requestId];
}
