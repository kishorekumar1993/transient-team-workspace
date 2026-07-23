import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Result<UserEntity, Failure>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.signUp(email: email, password: password);
      await localDataSource.cacheUser(userModel);
      return Success(userModel);
    } on AuthException catch (e) {
      return Error(AuthFailure(e.message));
    } on CacheException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity, Failure>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.login(email: email, password: password);
      await localDataSource.cacheUser(userModel);
      return Success(userModel);
    } on AuthException catch (e) {
      return Error(AuthFailure(e.message));
    } on CacheException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCachedUser();
      return const Success(null);
    } on AuthException catch (e) {
      return Error(AuthFailure(e.message));
    } on CacheException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity?, Failure>> getCurrentUser() async {
    try {
      // 1. Try local cache first for synchronous or offline checks.
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Success(cachedUser);
      }
      
      // 2. Check remote if cache is empty (e.g. initial run)
      final remoteUser = await remoteDataSource.getCurrentUser();
      if (remoteUser != null) {
        await localDataSource.cacheUser(remoteUser);
      }
      return Success(remoteUser);
    } on AuthException catch (e) {
      return Error(AuthFailure(e.message));
    } on CacheException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Success(null);
    } on AuthException catch (e) {
      return Error(AuthFailure(e.message));
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }
}
