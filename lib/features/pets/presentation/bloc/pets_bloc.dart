import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/pets_repository.dart';
import 'pets_event.dart';
import 'pets_state.dart';

/// Bloc para gestionar el estado de las mascotas.
@injectable
class PetsBloc extends Bloc<PetsEvent, PetsState> {
  final PetsRepository repository;

  PetsBloc(this.repository) : super(PetsInitial()) {
    // Manejo de eventos
    on<PetsLoadRequested>(_onLoadRequested);
    on<PetCreateRequested>(_onCreateRequested);
    on<PetUpdateRequested>(_onUpdateRequested);
    on<PetDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    PetsLoadRequested event,
    Emitter<PetsState> emit,
  ) async {
    emit(PetsLoading());

    await emit.forEach(
      repository.watchPetsByShelter(event.shelterId),
      onData: (pets) => PetsLoaded(pets),
      onError: (error, stackTrace) => PetsError(error.toString()),
    );
  }

  Future<void> _onCreateRequested(
    PetCreateRequested event,
    Emitter<PetsState> emit,
  ) async {
    emit(PetsLoading());

    final result = await repository.createPet(event.pet);

    result.fold(
      (failure) => emit(PetsError(failure.message)),
      (createdPet) {
        emit(PetsOperationSuccess(
          'Mascota creada exitosamente',
          createdPet: createdPet,
        ));
        // Recargar la lista
        add(PetsLoadRequested(createdPet.shelterId));
      },
    );
  }

  Future<void> _onUpdateRequested(
    PetUpdateRequested event,
    Emitter<PetsState> emit,
  ) async {
    emit(PetsLoading());

    final result = await repository.updatePet(event.pet);

    result.fold(
      (failure) => emit(PetsError(failure.message)),
      (updatedPet) {
        emit(const PetsOperationSuccess('Mascota actualizada exitosamente'));
        add(PetsLoadRequested(updatedPet.shelterId));
      },
    );
  }

  Future<void> _onDeleteRequested(
    PetDeleteRequested event,
    Emitter<PetsState> emit,
  ) async {
    emit(PetsLoading());

    final result = await repository.deletePet(event.petId);

    result.fold(
      (failure) => emit(PetsError(failure.message)),
      (_) => emit(const PetsOperationSuccess('Mascota eliminada exitosamente')),
    );
  }
}
