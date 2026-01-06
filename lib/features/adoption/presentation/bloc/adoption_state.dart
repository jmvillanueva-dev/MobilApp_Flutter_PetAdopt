import 'package:equatable/equatable.dart';
import '../../domain/entities/adoption_request_entity.dart';

sealed class AdoptionState extends Equatable {
  const AdoptionState();

  @override
  List<Object?> get props => [];
}

final class AdoptionInitial extends AdoptionState {}

final class AdoptionLoading extends AdoptionState {}

final class AdoptionLoaded extends AdoptionState {
  final List<AdoptionRequestEntity> requests;

  const AdoptionLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

final class AdoptionOperationSuccess extends AdoptionState {
  final String message;
  final AdoptionRequestEntity? request;

  const AdoptionOperationSuccess(this.message, {this.request});

  @override
  List<Object?> get props => [message, request];
}

final class AdoptionError extends AdoptionState {
  final String message;

  const AdoptionError(this.message);

  @override
  List<Object?> get props => [message];
}
