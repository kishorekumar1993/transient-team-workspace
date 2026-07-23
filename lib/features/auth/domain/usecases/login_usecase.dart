import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Result<UserEntity, Failure>> call({
    required String email,
    required String password,
  }) {
    return repository.login(email: email, password: password);
  }
}
