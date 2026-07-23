import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transient/core/error/failures.dart';
import 'package:transient/features/auth/domain/entities/user_entity.dart';
import 'package:transient/features/auth/domain/repositories/auth_repository.dart';
import 'package:transient/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:transient/features/auth/domain/usecases/login_usecase.dart';
import 'package:transient/features/auth/domain/usecases/logout_usecase.dart';
import 'package:transient/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:transient/features/auth/domain/usecases/signup_usecase.dart';
import 'package:transient/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient/features/auth/presentation/bloc/auth_event.dart';
import 'package:transient/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository implements AuthRepository {
  UserEntity? mockUser;
  bool shouldFail = false;
  String failMessage = 'Auth Failed';

  @override
  Future<Result<UserEntity?, Failure>> getCurrentUser() async {
    if (shouldFail) return Error(AuthFailure(failMessage));
    return Success(mockUser);
  }

  @override
  Future<Result<UserEntity, Failure>> login({
    required String email,
    required String password,
  }) async {
    if (shouldFail) return Error(AuthFailure(failMessage));
    final user = UserEntity(id: '123', email: email);
    mockUser = user;
    return Success(user);
  }

  @override
  Future<Result<UserEntity, Failure>> signUp({
    required String email,
    required String password,
  }) async {
    if (shouldFail) return Error(AuthFailure(failMessage));
    final user = UserEntity(id: '123', email: email);
    mockUser = user;
    return Success(user);
  }

  @override
  Future<Result<void, Failure>> logout() async {
    if (shouldFail) return Error(AuthFailure(failMessage));
    mockUser = null;
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> sendPasswordResetEmail(String email) async {
    if (shouldFail) return Error(AuthFailure(failMessage));
    return const Success(null);
  }
}

void main() {
  late MockAuthRepository mockRepository;
  late GetCurrentUserUseCase getCurrentUserUseCase;
  late LoginUseCase loginUseCase;
  late SignUpUseCase signUpUseCase;
  late LogoutUseCase logoutUseCase;
  late ResetPasswordUseCase resetPasswordUseCase;
  late AuthBloc authBloc;

  final tUser = const UserEntity(id: '123', email: 'test@workspace.com');

  setUp(() {
    mockRepository = MockAuthRepository();
    getCurrentUserUseCase = GetCurrentUserUseCase(mockRepository);
    loginUseCase = LoginUseCase(mockRepository);
    signUpUseCase = SignUpUseCase(mockRepository);
    logoutUseCase = LogoutUseCase(mockRepository);
    resetPasswordUseCase = ResetPasswordUseCase(mockRepository);

    authBloc = AuthBloc(
      getCurrentUserUseCase: getCurrentUserUseCase,
      loginUseCase: loginUseCase,
      signUpUseCase: signUpUseCase,
      logoutUseCase: logoutUseCase,
      resetPasswordUseCase: resetPasswordUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state should be AuthInitial', () {
    expect(authBloc.state, isA<AuthInitial>());
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when a user session is cached',
      build: () {
        mockRepository.mockUser = tUser;
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>().having(
          (state) => state.user?.email,
          'email',
          tUser.email,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no user session is cached',
      build: () {
        mockRepository.mockUser = null;
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<Unauthenticated>(),
      ],
    );
  });

  group('AuthLoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when login is successful',
      build: () => authBloc,
      act: (bloc) => bloc.add(const AuthLoginSubmitted(
        email: 'test@workspace.com',
        password: 'password',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>().having(
          (state) => state.user?.email,
          'email',
          'test@workspace.com',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        mockRepository.shouldFail = true;
        mockRepository.failMessage = 'Invalid credentials';
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginSubmitted(
        email: 'test@workspace.com',
        password: 'password',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (state) => state.message,
          'message',
          'Invalid credentials',
        ),
      ],
    );
   group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when logout is successful',
      build: () {
        mockRepository.mockUser = tUser;
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<Unauthenticated>(),
      ],
    );
  });
  });
}
