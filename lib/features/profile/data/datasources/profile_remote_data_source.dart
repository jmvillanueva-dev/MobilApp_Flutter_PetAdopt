import '../../../auth/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getProfile(String userId);
  Future<UserModel> updateProfile(String userId, Map<String, dynamic> data);
}
