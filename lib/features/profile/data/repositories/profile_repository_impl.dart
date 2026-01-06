import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../datasources/profile_remote_data_source.dart';
import '../../domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, UserEntity>> getProfile(String userId) async {
    try {
      final user = await remoteDataSource.getProfile(userId);
      return Right(user.toEntity());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> updateProfile(
    String userId, {
    String? displayName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (address != null) data['address'] = address;

      final user = await remoteDataSource.updateProfile(userId, data);
      return Right(user.toEntity());
    } catch (e) {
      return Left(e.toString());
    }
  }
}
