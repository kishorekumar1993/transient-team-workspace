import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source_impl.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/signup_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../network/mock_task_api_interceptor.dart';
import '../network/network_info.dart';
import '../persistence/local_storage.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ---------------------------------------------------------------------------
  // External & Core Dependencies
  // ---------------------------------------------------------------------------
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);
  sl.registerLazySingleton<LocalStorage>(() => LocalStorage(sl()));

  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Configure Dio with the Mock API Interceptor
  final dio = Dio();
  dio.interceptors.add(MockTaskApiInterceptor());
  sl.registerLazySingleton<Dio>(() => dio);

  // ---------------------------------------------------------------------------
  // Authentication Feature
  // ---------------------------------------------------------------------------

  // Fail-safe selection of Remote Auth Source depending on Firebase configuration status
  late AuthRemoteDataSource authRemoteDataSource;
  try {
    final authInstance = FirebaseAuth.instance;
    authRemoteDataSource = FirebaseAuthRemoteDataSourceImpl(authInstance);
    // ignore: avoid_print
    print('DI Setup: FirebaseAuth initialized successfully.');
  } catch (e) {
    authRemoteDataSource = MockAuthRemoteDataSourceImpl(sl());
    // ignore: avoid_print
    print('DI Setup: FirebaseAuth check failed (likely missing configuration). Falling back to Mock Auth Source.');
  }

  sl.registerSingleton<AuthRemoteDataSource>(authRemoteDataSource);
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ));

  // Auth Use Cases
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Auth BLoC (registered as factory since we rebuild it when routes load)
  sl.registerFactory(() => AuthBloc(
        getCurrentUserUseCase: sl(),
        loginUseCase: sl(),
        signUpUseCase: sl(),
        logoutUseCase: sl(),
      ));

}
