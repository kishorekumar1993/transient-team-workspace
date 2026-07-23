import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LoginUseCase loginUseCase;
  final SignUpUseCase signUpUseCase;
  final LogoutUseCase logoutUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthBloc({
    required this.getCurrentUserUseCase,
    required this.loginUseCase,
    required this.signUpUseCase,
    required this.logoutUseCase,
    required this.resetPasswordUseCase,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginSubmitted>(_onAuthLoginSubmitted);
    on<AuthSignUpSubmitted>(_onAuthSignUpSubmitted);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await getCurrentUserUseCase();
    result.fold(
      (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const Unauthenticated());
        }
      },
      (failure) => emit(Unauthenticated(errorMessage: failure.message)),
    );
  }

  Future<void> _onAuthLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(email: event.email, password: event.password);
    result.fold(
      (user) => emit(Authenticated(user)),
      (failure) => emit(AuthError(failure.message)),
    );
  }

  Future<void> _onAuthSignUpSubmitted(
    AuthSignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signUpUseCase(email: event.email, password: event.password);
    result.fold(
      (user) => emit(Authenticated(user)),
      (failure) => emit(AuthError(failure.message)),
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await logoutUseCase();
    result.fold(
      (_) => emit(const Unauthenticated()),
      (failure) => emit(AuthError(failure.message)),
    );
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await resetPasswordUseCase(event.email);
    result.fold(
      (_) => emit(const AuthActionSuccess('Password reset link sent to your email')),
      (failure) => emit(AuthError(failure.message)),
    );
  }
}
