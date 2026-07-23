import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Result<UserEntity, Failure>> signUp({
    required String email,
    required String password,
  });

  Future<Result<UserEntity, Failure>> login({
    required String email,
    required String password,
  });

  Future<Result<void, Failure>> logout();

  Future<Result<UserEntity?, Failure>> getCurrentUser();
}
