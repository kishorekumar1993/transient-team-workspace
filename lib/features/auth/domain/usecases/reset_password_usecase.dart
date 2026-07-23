import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Result<void, Failure>> call(String email) {
    return repository.sendPasswordResetEmail(email);
  }
}
