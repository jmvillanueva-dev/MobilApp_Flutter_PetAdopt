import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/entities/pet_photo_entity.dart';
import '../../domain/repositories/pets_repository.dart';
import '../datasources/pets_remote_data_source.dart';
import '../models/pet_model.dart';

/// Implementación del repositorio de mascotas.
@LazySingleton(as: PetsRepository)
class PetsRepositoryImpl implements PetsRepository {
  final PetsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PetsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<PetEntity>>> getPetsByShelter(
      String shelterId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final pets = await remoteDataSource.getPetsByShelter(shelterId);
      return Right(pets.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PetEntity>>> getAvailablePets(
      {String? query, String? species}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final pets = await remoteDataSource.getAvailablePets(
          query: query, species: species);
      return Right(pets.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PetEntity>> getPetById(String petId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final pet = await remoteDataSource.getPetById(petId);
      return Right(pet.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PetEntity>> createPet(PetEntity pet) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final petModel = PetModel.fromEntity(pet);
      final createdPet = await remoteDataSource.createPet(petModel);
      return Right(createdPet.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PetEntity>> updatePet(PetEntity pet) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final petModel = PetModel.fromEntity(pet);
      final updatedPet = await remoteDataSource.updatePet(petModel);
      return Right(updatedPet.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePet(String petId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      await remoteDataSource.deletePet(petId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PetPhotoEntity>>> getPetPhotos(
      String petId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final photos = await remoteDataSource.getPetPhotos(petId);
      return Right(photos.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPetPhoto({
    required String petId,
    required String filePath,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      // Obtener userId (implementar según tu lógica de auth)
      final userId = 'user-id'; // TODO: obtener del auth actual
      final photoUrl = await remoteDataSource.uploadPetPhoto(
        userId: userId,
        petId: petId,
        filePath: filePath,
      );
      return Right(photoUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePetPhoto(String photoId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      // Note: necesitamos photoUrl también, se manejará en Fase 3
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<PetEntity> watchPet(String petId) {
    return remoteDataSource.watchPet(petId).map((model) => model.toEntity());
  }

  @override
  Stream<List<PetPhotoEntity>> watchPetPhotos(String petId) {
    return remoteDataSource
        .watchPetPhotos(petId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}
