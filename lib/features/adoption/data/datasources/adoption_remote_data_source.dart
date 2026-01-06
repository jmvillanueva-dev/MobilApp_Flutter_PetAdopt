import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/adoption_request_model.dart';

@injectable
class AdoptionRemoteDataSource {
  final SupabaseClient _supabaseClient;

  AdoptionRemoteDataSource(this._supabaseClient);

  /// Crea una nueva solicitud de adopción
  Future<AdoptionRequestModel> createRequest({
    required String petId,
    required String adopterId,
    required String shelterId,
    String? message,
  }) async {
    try {
      final response = await _supabaseClient
          .from('adoption_requests')
          .insert({
            'pet_id': petId,
            'adopter_id': adopterId,
            'shelter_id': shelterId,
            'message': message,
          })
          .select()
          .single();

      return AdoptionRequestModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException && e.code == '23505') {
        throw Exception('Ya tienes una solicitud pendiente para esta mascota.');
      }
      throw Exception('Error al crear solicitud: $e');
    }
  }

  /// Obtiene las solicitudes enviadas por un adoptante
  Future<List<AdoptionRequestModel>> getRequestsByAdopter(
      String adopterId) async {
    try {
      final response = await _supabaseClient
          .from('adoption_requests')
          .select(
              '*, pets(name, primary_photo_url), profiles!adoption_requests_adopter_id_fkey(display_name)')
          .eq('adopter_id', adopterId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AdoptionRequestModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes: $e');
    }
  }

  /// Obtiene las solicitudes recibidas por un refugio
  Future<List<AdoptionRequestModel>> getRequestsByShelter(
      String shelterId) async {
    try {
      final response = await _supabaseClient
          .from('adoption_requests')
          .select(
              '*, pets(name, primary_photo_url), profiles!adoption_requests_adopter_id_fkey(display_name)')
          .eq('shelter_id', shelterId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AdoptionRequestModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes recibidas: $e');
    }
  }

  /// Actualiza el estado de una solicitud
  Future<AdoptionRequestModel> updateRequestStatus(
    String requestId,
    String status,
  ) async {
    try {
      final response = await _supabaseClient
          .from('adoption_requests')
          .update({'status': status})
          .eq('id', requestId)
          .select(
              '*, pets(name, primary_photo_url), profiles!adoption_requests_adopter_id_fkey(display_name)')
          .single();

      // Si se aprueba, actualizar el estado de la mascota a 'en_proceso' o 'adoptado'
      // Esto podría hacerse via trigger, pero lo haremos aquí por simplicidad inicial
      if (status == 'aprobada') {
        final request = AdoptionRequestModel.fromJson(response);
        await _supabaseClient
            .from('pets')
            .update({'status': 'adoptado'}) // O 'en_proceso' según flujo
            .eq('id', request.petId);
      }

      return AdoptionRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  /// Elimina una solicitud de adopción
  Future<void> deleteRequest(String requestId) async {
    try {
      await _supabaseClient
          .from('adoption_requests')
          .delete()
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Error al eliminar solicitud: $e');
    }
  }

  /// Escucha cambios en tiempo real de las solicitudes de un adoptante
  Stream<List<AdoptionRequestModel>> watchRequestsByAdopter(String adopterId) {
    return _supabaseClient
        .from('adoption_requests')
        .stream(primaryKey: ['id'])
        .eq('adopter_id', adopterId)
        .asyncMap((_) async {
          // Re-fetch completo para traer los datos relacionados (joins no soportados en stream directo)
          return await getRequestsByAdopter(adopterId);
        });
  }

  /// Escucha cambios en tiempo real de las solicitudes de un refugio
  Stream<List<AdoptionRequestModel>> watchRequestsByShelter(String shelterId) {
    return _supabaseClient
        .from('adoption_requests')
        .stream(primaryKey: ['id'])
        .eq('shelter_id', shelterId)
        .asyncMap((_) async {
          // Re-fetch completo
          return await getRequestsByShelter(shelterId);
        });
  }
}
