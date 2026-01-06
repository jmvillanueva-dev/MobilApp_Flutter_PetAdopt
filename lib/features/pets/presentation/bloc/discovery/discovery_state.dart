part of 'discovery_bloc.dart';

sealed class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => [];
}

final class DiscoveryInitial extends DiscoveryState {}

final class DiscoveryLoading extends DiscoveryState {}

final class DiscoveryLoaded extends DiscoveryState {
  final List<PetEntity> pets;
  final String activeSpeciesFilter;

  const DiscoveryLoaded({
    required this.pets,
    this.activeSpeciesFilter = 'todos',
  });

  @override
  List<Object?> get props => [pets, activeSpeciesFilter];
}

final class DiscoveryError extends DiscoveryState {
  final String message;

  const DiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}
