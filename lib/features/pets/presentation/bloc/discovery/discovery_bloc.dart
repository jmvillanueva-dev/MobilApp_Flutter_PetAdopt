import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/pet_entity.dart';
import '../../../domain/repositories/pets_repository.dart';

part 'discovery_event.dart';
part 'discovery_state.dart';

@injectable
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final PetsRepository repository;

  DiscoveryBloc(this.repository) : super(DiscoveryInitial()) {
    on<LoadDiscoveryPets>(_onLoadDiscoveryPets);
  }

  Future<void> _onLoadDiscoveryPets(
      LoadDiscoveryPets event, Emitter<DiscoveryState> emit) async {
    emit(DiscoveryLoading());

    final species = event.species ?? 'todos';

    await emit.forEach(
      repository.watchAvailablePets(
        query: event.query,
        species: species,
      ),
      onData: (pets) => DiscoveryLoaded(
        pets: pets,
        activeSpeciesFilter: species,
      ),
      onError: (error, stackTrace) => DiscoveryError(error.toString()),
    );
  }
}
