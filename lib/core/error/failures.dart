abstract class Failure {
  final String message;
  const Failure([this.message = 'An unexpected error occurred']);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache read/write error occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

// Custom functional programming wrapper for clean error handling
abstract class Result<S, F extends Failure> {
  const Result();

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Error<S, F>;

  S? get successValue =>
      this is Success<S, F> ? (this as Success<S, F>).value : null;
  F? get failureValue =>
      this is Error<S, F> ? (this as Error<S, F>).failure : null;

  T fold<T>(T Function(S success) onSuccess, T Function(F failure) onFailure) {
    if (this is Success<S, F>) {
      return onSuccess((this as Success<S, F>).value);
    } else {
      return onFailure((this as Error<S, F>).failure);
    }
  }
}

class Success<S, F extends Failure> extends Result<S, F> {
  final S value;
  const Success(this.value);
}

class Error<S, F extends Failure> extends Result<S, F> {
  final F failure;
  const Error(this.failure);
}
