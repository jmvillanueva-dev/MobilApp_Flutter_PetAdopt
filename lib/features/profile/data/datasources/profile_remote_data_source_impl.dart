import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/auth/data/models/user_model.dart';
import 'profile_remote_data_source.dart';

@LazySingleton(as: ProfileRemoteDataSource)
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProfileRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserModel> getProfile(String userId) async {
    try {
      // Fetch data from 'profiles' table first (custom data)
      final profileResponse = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Get basic auth data
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Merge logic could go here, but for now we rely on Supabase User object
      // primarily, with augmented fields from profiles if needed.
      // Actually, UserModel.fromSupabaseUser uses user.userMetadata.
      // To strictly follow 'profiles' table being the source of truth for display_name/role:

      // We might need a mapper that takes both.
      // For simplicity, we'll assume auth metadata is kept in sync via triggers OR
      // we reconstruct UserModel using the profile data.

      return UserModel(
        id: userId,
        email: profileResponse['email'] ?? user.email!,
        displayName: profileResponse['display_name'],
        photoUrl: profileResponse['avatar_url'],
        role: profileResponse['role'],
        createdAt:
            DateTime.parse(profileResponse['updated_at'] ?? user.createdAt),
      );
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  @override
  Future<UserModel> updateProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      // Update 'profiles' table
      final response = await supabaseClient
          .from('profiles')
          .update(data)
          .eq('id', userId)
          .select()
          .single();

      // Also update Auth metadata to keep them in sync (optional but recommended)
      await supabaseClient.auth.updateUser(
        UserAttributes(
          data: data,
        ),
      );

      // Re-fetch or construct updated model
      return await getProfile(userId);
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}
