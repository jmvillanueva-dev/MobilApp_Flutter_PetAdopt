part of 'discovery_bloc.dart';

sealed class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

final class LoadDiscoveryPets extends DiscoveryEvent {
  final String? query;
  final String? species;

  const LoadDiscoveryPets({this.query, this.species});

  @override
  List<Object?> get props => [query, species];
}
