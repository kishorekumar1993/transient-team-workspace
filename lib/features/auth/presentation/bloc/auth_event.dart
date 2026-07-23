abstract class AuthEvent {
  const AuthEvent();
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({required this.email, required this.password});
}

class AuthSignUpSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthSignUpSubmitted({required this.email, required this.password});
}

class AuthLogoutRequested extends AuthEvent {}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested(this.email);
}
