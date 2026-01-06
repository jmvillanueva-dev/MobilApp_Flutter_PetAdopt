import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/adoption_repository.dart';
import 'adoption_event.dart';
import 'adoption_state.dart';

@injectable
class AdoptionBloc extends Bloc<AdoptionEvent, AdoptionState> {
  final AdoptionRepository repository;
  final SupabaseClient supabaseClient;

  AdoptionBloc(this.repository, this.supabaseClient)
      : super(AdoptionInitial()) {
    on<CreateAdoptonRequest>(_onCreateRequest);
    on<LoadAdopterRequests>(_onLoadAdopterRequests);
    on<LoadShelterRequests>(_onLoadShelterRequests);
    on<UpdateRequestStatus>(_onUpdateStatus);
    on<DeleteAdoptionRequest>(_onDeleteRequest);
  }

  Future<void> _onCreateRequest(
    CreateAdoptonRequest event,
    Emitter<AdoptionState> emit,
  ) async {
    emit(AdoptionLoading());

    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      emit(const AdoptionError('No hay usuario autenticado'));
      return;
    }

    final result = await repository.createRequest(
      petId: event.petId,
      adopterId: userId,
      shelterId: event.shelterId,
      message: event.message,
    );

    result.fold(
      (failure) => emit(AdoptionError(failure.message)),
      (request) => emit(AdoptionOperationSuccess(
        'Solicitud enviada exitosamente',
        request: request,
      )),
    );
  }

  Future<void> _onLoadAdopterRequests(
    LoadAdopterRequests event,
    Emitter<AdoptionState> emit,
  ) async {
    emit(AdoptionLoading());

    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      emit(const AdoptionError('No hay usuario autenticado'));
      return;
    }

    await emit.forEach(
      repository.watchRequestsByAdopter(userId),
      onData: (requests) => AdoptionLoaded(requests),
      onError: (error, stackTrace) => AdoptionError(error.toString()),
    );
  }

  Future<void> _onLoadShelterRequests(
    LoadShelterRequests event,
    Emitter<AdoptionState> emit,
  ) async {
    emit(AdoptionLoading());

    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      emit(const AdoptionError('No hay usuario autenticado'));
      return;
    }

    await emit.forEach(
      repository.watchRequestsByShelter(userId),
      onData: (requests) => AdoptionLoaded(requests),
      onError: (error, stackTrace) => AdoptionError(error.toString()),
    );
  }

  Future<void> _onUpdateStatus(
    UpdateRequestStatus event,
    Emitter<AdoptionState> emit,
  ) async {
    emit(AdoptionLoading());

    final result = await repository.updateRequestStatus(
      event.requestId,
      event.status,
    );

    result.fold(
      (failure) => emit(AdoptionError(failure.message)),
      (request) {
        emit(AdoptionOperationSuccess(
          'Estado actualizado a ${event.status}',
          request: request,
        ));
        add(LoadShelterRequests()); // Recargar lista para refugio
      },
    );
  }

  Future<void> _onDeleteRequest(
    DeleteAdoptionRequest event,
    Emitter<AdoptionState> emit,
  ) async {
    // No emitimos Loading para no interrumpir el stream visualmente de forma brusca
    final result = await repository.deleteRequest(event.requestId);

    result.fold(
      (failure) => emit(AdoptionError(failure.message)),
      (_) => emit(const AdoptionOperationSuccess('Solicitud eliminada')),
    );
  }
}
