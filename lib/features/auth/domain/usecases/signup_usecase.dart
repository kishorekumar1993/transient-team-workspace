import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Result<UserEntity, Failure>> call({
    required String email,
    required String password,
  }) {
    return repository.signUp(email: email, password: password);
  }
}
