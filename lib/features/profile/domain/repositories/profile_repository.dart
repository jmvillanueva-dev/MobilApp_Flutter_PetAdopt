import 'package:dartz/dartz.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<Either<String, UserEntity>> getProfile(String userId);
  Future<Either<String, UserEntity>> updateProfile(
    String userId, {
    String? displayName,
    String? phoneNumber,
    String? address,
  });
}
