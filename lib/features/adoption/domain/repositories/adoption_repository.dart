import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/adoption_request_entity.dart';

abstract class AdoptionRepository {
  Future<Either<Failure, AdoptionRequestEntity>> createRequest({
    required String petId,
    required String adopterId,
    required String shelterId,
    String? message,
  });

  Future<Either<Failure, List<AdoptionRequestEntity>>> getRequestsByAdopter(
      String adopterId);

  Stream<List<AdoptionRequestEntity>> watchRequestsByAdopter(String adopterId);

  Future<Either<Failure, List<AdoptionRequestEntity>>> getRequestsByShelter(
      String shelterId);

  Stream<List<AdoptionRequestEntity>> watchRequestsByShelter(String shelterId);

  Future<Either<Failure, AdoptionRequestEntity>> updateRequestStatus(
    String requestId,
    String status,
  );

  Future<Either<Failure, Unit>> deleteRequest(String requestId);
}
