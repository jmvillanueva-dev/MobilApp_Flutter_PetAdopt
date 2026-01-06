import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/adoption_request_entity.dart';
import '../../domain/repositories/adoption_repository.dart';
import '../datasources/adoption_remote_data_source.dart';

@LazySingleton(as: AdoptionRepository)
class AdoptionRepositoryImpl implements AdoptionRepository {
  final AdoptionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AdoptionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AdoptionRequestEntity>> createRequest({
    required String petId,
    required String adopterId,
    required String shelterId,
    String? message,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final request = await remoteDataSource.createRequest(
        petId: petId,
        adopterId: adopterId,
        shelterId: shelterId,
        message: message,
      );
      return Right(request.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdoptionRequestEntity>>> getRequestsByAdopter(
      String adopterId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final requests = await remoteDataSource.getRequestsByAdopter(adopterId);
      return Right(requests.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<AdoptionRequestEntity>> watchRequestsByAdopter(String adopterId) {
    return remoteDataSource
        .watchRequestsByAdopter(adopterId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<Either<Failure, List<AdoptionRequestEntity>>> getRequestsByShelter(
      String shelterId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final requests = await remoteDataSource.getRequestsByShelter(shelterId);
      return Right(requests.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<AdoptionRequestEntity>> watchRequestsByShelter(String shelterId) {
    return remoteDataSource
        .watchRequestsByShelter(shelterId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<Either<Failure, AdoptionRequestEntity>> updateRequestStatus(
      String requestId, String status) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final request =
          await remoteDataSource.updateRequestStatus(requestId, status);
      return Right(request.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteRequest(String requestId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }
    try {
      await remoteDataSource.deleteRequest(requestId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
