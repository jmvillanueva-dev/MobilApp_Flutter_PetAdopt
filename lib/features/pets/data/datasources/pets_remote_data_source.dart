import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_model.dart';
import '../models/pet_photo_model.dart';

/// DataSource remoto para operaciones de mascotas con Supabase.
///
/// Maneja todas las operaciones de base de datos y storage relacionadas
/// con mascotas y sus fotos.
@injectable
class PetsRemoteDataSource {
  final SupabaseClient _supabaseClient;

  PetsRemoteDataSource(this._supabaseClient);

  /// Obtiene todas las mascotas de un refugio
  Future<List<PetModel>> getPetsByShelter(String shelterId) async {
    try {
      final response = await _supabaseClient
          .from('pets')
          .select()
          .eq('shelter_id', shelterId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener mascotas: $e');
    }
  }

  /// Obtiene mascotas disponibles para adopción (con filtros opcionales)
  Future<List<PetModel>> getAvailablePets(
      {String? query, String? species}) async {
    try {
      var builder =
          _supabaseClient.from('pets').select().eq('status', 'disponible');

      if (query != null && query.isNotEmpty) {
        // Buscando por nombre insensible a mayúsculas/minúsculas
        builder = builder.ilike('name', '%$query%');
      }

      if (species != null &&
          species.isNotEmpty &&
          species.toLowerCase() != 'todos') {
        builder = builder.eq('species', species.toLowerCase());
      }

      final response = await builder.order('created_at', ascending: false);

      return (response as List)
          .map((json) => PetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar mascotas: $e');
    }
  }

  /// Obtiene una mascota por ID
  Future<PetModel> getPetById(String petId) async {
    try {
      final response =
          await _supabaseClient.from('pets').select().eq('id', petId).single();

      return PetModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener mascota: $e');
    }
  }

  /// Crea una nueva mascota
  Future<PetModel> createPet(PetModel pet) async {
    try {
      final data = pet.toJson();
      // Remover campos que se autogeneran
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      final response =
          await _supabaseClient.from('pets').insert(data).select().single();

      return PetModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear mascota: $e');
    }
  }

  /// Actualiza una mascota existente
  Future<PetModel> updatePet(PetModel pet) async {
    try {
      final data = pet.toJson();
      // Remover campos que no se deben actualizar manualmente
      data.remove('id');
      data.remove('shelter_id');
      data.remove('created_at');
      data.remove('updated_at'); // Se actualiza automáticamente por trigger

      await _supabaseClient.from('pets').update(data).eq('id', pet.id);

      // Re-obtener la mascota actualizada
      return await getPetById(pet.id);
    } catch (e) {
      throw Exception('Error al actualizar mascota: $e');
    }
  }

  /// Elimina una mascota y todas sus fotos
  Future<void> deletePet(String petId) async {
    try {
      // Primero obtener todas las fotos para eliminarlas del storage
      final photos = await getPetPhotos(petId);

      // Eliminar cada foto del storage
      for (var photo in photos) {
        try {
          // Extraer ruta del storage desde URL
          final uri = Uri.parse(photo.photoUrl);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexOf('pet-photos');
          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await _supabaseClient.storage
                .from('pet-photos')
                .remove([storagePath]);
          }
        } catch (e) {
          print('Error al eliminar foto del storage: $e');
        }
      }

      // Luego eliminar la mascota (cascade eliminará pet_photos automáticamente)
      await _supabaseClient.from('pets').delete().eq('id', petId);
    } catch (e) {
      throw Exception('Error al eliminar mascota: $e');
    }
  }

  /// Obtiene las fotos de una mascota
  Future<List<PetPhotoModel>> getPetPhotos(String petId) async {
    try {
      final response = await _supabaseClient
          .from('pet_photos')
          .select()
          .eq('pet_id', petId)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => PetPhotoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener fotos: $e');
    }
  }

  /// Sube una foto al storage de Supabase
  ///
  /// [userId] ID del usuario (refugio)
  /// [petId] ID de la mascota
  /// [filePath] Ruta local del archivo de imagen
  ///
  /// Retorna la URL pública de la foto subida
  Future<String> uploadPetPhoto({
    required String userId,
    required String petId,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '$userId/$petId/$fileName';

      // Subir archivo al bucket 'pet-photos'
      await _supabaseClient.storage
          .from('pet-photos')
          .upload(storagePath, file);

      // Obtener URL pública
      final publicUrl =
          _supabaseClient.storage.from('pet-photos').getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir foto: $e');
    }
  }

  /// Crea un registro de foto en la base de datos
  Future<PetPhotoModel> createPetPhoto({
    required String petId,
    required String photoUrl,
    required int displayOrder,
  }) async {
    try {
      final response = await _supabaseClient
          .from('pet_photos')
          .insert({
            'pet_id': petId,
            'photo_url': photoUrl,
            'display_order': displayOrder,
          })
          .select()
          .single();

      return PetPhotoModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al registrar foto: $e');
    }
  }

  /// Elimina una foto (registro y archivo)
  Future<void> deletePetPhoto(String photoId, String photoUrl) async {
    try {
      // Extraer la ruta del storage desde la URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('pet-photos');
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');

        // Eliminar archivo del storage
        await _supabaseClient.storage.from('pet-photos').remove([storagePath]);
      }

      // Eliminar registro de la base de datos
      await _supabaseClient.from('pet_photos').delete().eq('id', photoId);
    } catch (e) {
      throw Exception('Error al eliminar foto: $e');
    }
  }

  /// Actualiza la foto principal de una mascota
  Future<void> updatePrimaryPhoto(String petId, String photoUrl) async {
    try {
      await _supabaseClient
          .from('pets')
          .update({'primary_photo_url': photoUrl}).eq('id', petId);
    } catch (e) {
      throw Exception('Error al actualizar foto principal: $e');
    }
  }

  /// Reemplaza todas las fotos de una mascota (para edición)
  Future<void> replacePetPhotos({
    required String petId,
    required List<String> photoUrls,
  }) async {
    try {
      // 1. Eliminar todas las fotos existentes de la DB (no storage)
      await _supabaseClient.from('pet_photos').delete().eq('pet_id', petId);

      // 2. Insertar las nuevas fotos
      if (photoUrls.isNotEmpty) {
        final photosToInsert = photoUrls.asMap().entries.map((entry) {
          return {
            'pet_id': petId,
            'photo_url': entry.value,
            'display_order': entry.key,
          };
        }).toList();

        await _supabaseClient.from('pet_photos').insert(photosToInsert);
      }
    } catch (e) {
      throw Exception('Error al reemplazar fotos: $e');
    }
  }

  /// Escucha cambios en tiempo real de una mascota específica.
  ///
  /// Retorna un Stream que emite actualizaciones cada vez que la mascota cambia.
  Stream<PetModel> watchPet(String petId) {
    return _supabaseClient
        .from('pets')
        .stream(primaryKey: ['id'])
        .eq('id', petId)
        .map((data) {
          if (data.isEmpty) throw Exception('La mascota no existe');
          final json = data.first as Map<String, dynamic>;

          // Join con profiles para obtener info del refugio
          final shelterData = _supabaseClient
              .from('profiles')
              .select('display_name, phone_number, address')
              .eq('id', json['shelter_id'] as String)
              .maybeSingle(); // Use maybeSingle to handle null results

          return shelterData.then((profileJson) {
            if (profileJson != null) {
              json['profiles'] = profileJson;
            }
            return PetModel.fromJson(json);
          });
        })
        .asyncMap((future) => future);
  }

  /// Escucha cambios en tiempo real de las fotos de una mascota
  Stream<List<PetPhotoModel>> watchPetPhotos(String petId) {
    return _supabaseClient
        .from('pet_photos')
        .stream(primaryKey: ['id'])
        .eq('pet_id', petId)
        .order('display_order', ascending: true)
        .map((data) => data
            .map((json) => PetPhotoModel.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Escucha cambios en tiempo real de mascotas disponibles
  Stream<List<PetModel>> watchAvailablePets({String? query, String? species}) {
    return _supabaseClient
        .from('pets')
        .stream(primaryKey: ['id'])
        .eq('status', 'disponible')
        .asyncMap((_) async {
          // Re-fetch con filtros aplicados
          return await getAvailablePets(query: query, species: species);
        });
  }

  /// Escucha cambios en tiempo real de las mascotas de un refugio
  Stream<List<PetModel>> watchPetsByShelter(String shelterId) {
    return _supabaseClient
        .from('pets')
        .stream(primaryKey: ['id'])
        .eq('shelter_id', shelterId)
        .asyncMap((_) async {
          // Re-fetch para mantener el orden
          return await getPetsByShelter(shelterId);
        });
  }
}
