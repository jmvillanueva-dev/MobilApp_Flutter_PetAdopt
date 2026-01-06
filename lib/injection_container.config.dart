// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:app_petadopt/core/network/network_info.dart' as _i725;
import 'package:app_petadopt/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i961;
import 'package:app_petadopt/features/auth/data/repositories/auth_repository_impl.dart'
    as _i770;
import 'package:app_petadopt/features/auth/domain/repositories/auth_repository.dart'
    as _i738;
import 'package:app_petadopt/features/auth/domain/usecases/get_current_user.dart'
    as _i1008;
import 'package:app_petadopt/features/auth/domain/usecases/reset_password.dart'
    as _i608;
import 'package:app_petadopt/features/auth/domain/usecases/sign_in.dart'
    as _i449;
import 'package:app_petadopt/features/auth/domain/usecases/sign_out.dart'
    as _i157;
import 'package:app_petadopt/features/auth/domain/usecases/sign_up.dart'
    as _i508;
import 'package:app_petadopt/features/auth/presentation/bloc/auth_bloc.dart'
    as _i988;
import 'package:app_petadopt/features/pets/data/datasources/pets_remote_data_source.dart'
    as _i177;
import 'package:app_petadopt/features/pets/data/repositories/pets_repository_impl.dart'
    as _i812;
import 'package:app_petadopt/features/pets/domain/repositories/pets_repository.dart'
    as _i148;
import 'package:app_petadopt/features/pets/presentation/bloc/discovery/discovery_bloc.dart'
    as _i234;
import 'package:app_petadopt/features/pets/presentation/bloc/pets_bloc.dart'
    as _i900;
import 'package:app_petadopt/features/profile/data/datasources/profile_remote_data_source.dart'
    as _i286;
import 'package:app_petadopt/features/profile/data/datasources/profile_remote_data_source_impl.dart'
    as _i367;
import 'package:app_petadopt/features/profile/data/repositories/profile_repository_impl.dart'
    as _i256;
import 'package:app_petadopt/features/profile/domain/repositories/profile_repository.dart'
    as _i360;
import 'package:app_petadopt/features/profile/presentation/bloc/profile_bloc.dart'
    as _i23;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i725.NetworkInfo>(
        () => _i725.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.factory<_i900.PetsBloc>(
        () => _i900.PetsBloc(gh<_i148.PetsRepository>()));
    gh.lazySingleton<_i286.ProfileRemoteDataSource>(
        () => _i367.ProfileRemoteDataSourceImpl(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i961.AuthRemoteDataSource>(
        () => _i961.AuthRemoteDataSourceImpl(gh<_i454.SupabaseClient>()));
    gh.factory<_i177.PetsRemoteDataSource>(
        () => _i177.PetsRemoteDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i360.ProfileRepository>(
        () => _i256.ProfileRepositoryImpl(gh<_i286.ProfileRemoteDataSource>()));
    gh.factory<_i23.ProfileBloc>(
        () => _i23.ProfileBloc(gh<_i360.ProfileRepository>()));
    gh.lazySingleton<_i148.PetsRepository>(() => _i812.PetsRepositoryImpl(
          remoteDataSource: gh<_i177.PetsRemoteDataSource>(),
          networkInfo: gh<_i725.NetworkInfo>(),
        ));
    gh.lazySingleton<_i738.AuthRepository>(() => _i770.AuthRepositoryImpl(
          remoteDataSource: gh<_i961.AuthRemoteDataSource>(),
          networkInfo: gh<_i725.NetworkInfo>(),
        ));
    gh.factory<_i1008.GetCurrentUser>(
        () => _i1008.GetCurrentUser(gh<_i738.AuthRepository>()));
    gh.factory<_i608.ResetPassword>(
        () => _i608.ResetPassword(gh<_i738.AuthRepository>()));
    gh.factory<_i449.SignIn>(() => _i449.SignIn(gh<_i738.AuthRepository>()));
    gh.factory<_i157.SignOut>(() => _i157.SignOut(gh<_i738.AuthRepository>()));
    gh.factory<_i508.SignUp>(() => _i508.SignUp(gh<_i738.AuthRepository>()));
    gh.factory<_i234.DiscoveryBloc>(
        () => _i234.DiscoveryBloc(gh<_i148.PetsRepository>()));
    gh.factory<_i988.AuthBloc>(() => _i988.AuthBloc(
          signIn: gh<_i449.SignIn>(),
          signUp: gh<_i508.SignUp>(),
          resetPassword: gh<_i608.ResetPassword>(),
          signOut: gh<_i157.SignOut>(),
          getCurrentUser: gh<_i1008.GetCurrentUser>(),
        ));
    return this;
  }
}
