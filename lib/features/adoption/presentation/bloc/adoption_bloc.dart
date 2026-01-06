import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/repositories/adoption_repository.dart';
import 'adoption_event.dart';
import 'adoption_state.dart';

@injectable
class AdoptionBloc extends Bloc<AdoptionEvent, AdoptionState> {
  final AdoptionRepository repository;
  final SupabaseClient supabaseClient;
  final NotificationService notificationService;

  // Track previous requests to detect new ones and status changes
  Set<String> _previousShelterRequestIds = {};
  Map<String, String> _previousAdopterRequestStatuses = {};

  AdoptionBloc(
    this.repository,
    this.supabaseClient,
    this.notificationService,
  ) : super(AdoptionInitial()) {
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
      onData: (requests) {
        // Track status changes: Map<requestId, status>
        final currentRequestStatuses = Map<String, String>.fromEntries(
          requests.map((r) => MapEntry(r.id, r.status)),
        );

        // Check for status changes from 'pendiente' to 'aprobada' or 'rechazada'
        for (final entry in currentRequestStatuses.entries) {
          final requestId = entry.key;
          final currentStatus = entry.value;
          final previousStatus = _previousAdopterRequestStatuses[requestId];

          // Only notify if status changed FROM 'pendiente' TO 'aprobada'/'rechazada'
          if (previousStatus == 'pendiente' &&
              (currentStatus == 'aprobada' || currentStatus == 'rechazada')) {
            final request = requests.firstWhere((r) => r.id == requestId);
            notificationService.showStatusChangeNotification(
              petName: request.petName ?? 'Mascota',
              status: currentStatus,
            );
          }
        }

        // Update tracking map for next iteration
        _previousAdopterRequestStatuses = currentRequestStatuses;

        return AdoptionLoaded(requests);
      },
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
      onData: (requests) {
        // Check for NEW pending requests (not seen before)
        final currentPendingIds = requests
            .where((r) => r.status == 'pendiente')
            .map((r) => r.id)
            .toSet();

        // Find truly new requests (IDs that weren't in previous set)
        final newRequestIds =
            currentPendingIds.difference(_previousShelterRequestIds);

        // Notify only for each NEW pending request
        for (final newRequestId in newRequestIds) {
          final request = requests.firstWhere((r) => r.id == newRequestId);
          notificationService.showNewRequestNotification(
            petName: request.petName ?? 'Mascota',
            adopterName: request.adopterNamr ?? 'Usuario',
          );
        }

        // Update the tracking set for next iteration
        _previousShelterRequestIds = currentPendingIds;

        return AdoptionLoaded(requests);
      },
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
