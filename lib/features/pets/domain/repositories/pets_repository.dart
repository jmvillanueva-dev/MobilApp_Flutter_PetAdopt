import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pet_entity.dart';
import '../entities/pet_photo_entity.dart';

/// Repositorio abstracto para operaciones relacionadas con mascotas.
///
/// Define el contrato que debe implementar el repositorio concreto.
abstract class PetsRepository {
  /// Obtiene todas las mascotas de un refugio específico.
  Future<Either<Failure, List<PetEntity>>> getPetsByShelter(String shelterId);

  /// Obtiene una mascota por su ID.
  Future<Either<Failure, PetEntity>> getPetById(String petId);

  /// Crea una nueva mascota.
  Future<Either<Failure, PetEntity>> createPet(PetEntity pet);

  /// Actualiza una mascota existente.
  Future<Either<Failure, PetEntity>> updatePet(PetEntity pet);

  /// Elimina una mascota.
  Future<Either<Failure, void>> deletePet(String petId);

  /// Obtiene las fotos de una mascota.
  Future<Either<Failure, List<PetPhotoEntity>>> getPetPhotos(String petId);

  /// Sube una foto de mascota al storage.
  /// Retorna la URL pública de la foto subida.
  Future<Either<Failure, String>> uploadPetPhoto({
    required String petId,
    required String filePath,
  });

  /// Elimina una foto de mascota del storage.
  Future<Either<Failure, void>> deletePetPhoto(String photoId);

  /// Escucha cambios en tiempo real de una mascota.
  Stream<PetEntity> watchPet(String petId);

  /// Escucha cambios en tiempo real de las fotos de una mascota.
  Stream<List<PetPhotoEntity>> watchPetPhotos(String petId);
}
