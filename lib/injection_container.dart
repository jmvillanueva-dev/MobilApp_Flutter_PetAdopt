import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'injection_container.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Register external dependencies
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // Features - Auth
  // (Assuming Auth dependencies are auto-generated or registered here.
  // Since I see @InjectableInit, I should trust the generator OR manually register if not using full generation.
  // The file shows `getIt.init()`. This implies using `injectable_generator`.
  // I annotated the classes with @LazySingleton/@injectable, so I just need to run build_runner.
  // BUT the user didn't ask me to run build_runner, and I should check if I can run it or if I need to manually register.
  // The user's prompt implies manual coding or standard flow.
  // Let's check `injection_container.config.dart`. If it exists, I should run build_runner.
  // If not, manual registration.
  // Wait, I saw `import 'injection_container.config.dart';` in line 6.
  // So I MUST run `flutter pub run build_runner build`.
  // I will skip manual registration here and run the command.)

  // Initialize injectable
  getIt.init();
}
