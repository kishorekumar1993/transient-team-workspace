import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient/core/network/network_info.dart';
import 'package:transient/core/theme/theme_cubit.dart';
import 'package:transient/features/auth/domain/entities/user_entity.dart';
import 'package:transient/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient/features/auth/presentation/bloc/auth_event.dart';
import 'package:transient/features/auth/presentation/bloc/auth_state.dart';
import 'package:transient/features/auth/presentation/pages/login_page.dart';
import 'package:transient/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:transient/features/tasks/presentation/bloc/task_list_state.dart';
import 'package:transient/features/tasks/presentation/pages/dashboard_page.dart';
import 'package:transient/main.dart';

// Stub network info for DashboardHomeTab initialization
class StubNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected => Future.value(true);

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(true);
}

// Modern mocks using mocktail and bloc_test
class MockThemeCubit extends MockCubit<ThemeMode> implements ThemeCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockTaskListBloc extends MockBloc<TaskListEvent, TaskListState>
    implements TaskListBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeTaskListEvent extends Fake implements TaskListEvent {}

void main() {
  late MockThemeCubit mockThemeCubit;
  late MockAuthBloc mockAuthBloc;
  late MockTaskListBloc mockTaskListBloc;

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeTaskListEvent());

    // Register mock network info in GetIt for DashboardHomeTab dependency lookup
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<NetworkInfo>()) {
      getIt.registerLazySingleton<NetworkInfo>(() => StubNetworkInfo());
    }
  });

  setUp(() {
    mockThemeCubit = MockThemeCubit();
    mockAuthBloc = MockAuthBloc();
    mockTaskListBloc = MockTaskListBloc();

    // Default stub states to avoid null check errors
    when(() => mockThemeCubit.state).thenReturn(ThemeMode.light);
    when(
      () => mockThemeCubit.stream,
    ).thenAnswer((_) => Stream.value(ThemeMode.light));

    when(() => mockTaskListBloc.state).thenReturn(const TaskListInitial());
    when(
      () => mockTaskListBloc.stream,
    ).thenAnswer((_) => Stream.value(const TaskListInitial()));
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<TaskListBloc>.value(value: mockTaskListBloc),
      ],
      child: const MaterialApp(home: AuthWrapper()),
    );
  }

  testWidgets('displays Loading Indicator when Auth state is loading', (
    WidgetTester tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthLoading());
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(AuthLoading()));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders LoginPage when state is Unauthenticated', (
    WidgetTester tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(const Unauthenticated()));

    // Set screen size to a standard desktop width to avoid RenderFlex overflows in tests
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('renders DashboardPage when state is Authenticated', (
    WidgetTester tester,
  ) async {
    const user = UserEntity(id: '123', email: 'test@workspace.com');
    when(() => mockAuthBloc.state).thenReturn(const Authenticated(user));
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(const Authenticated(user)));

    // Force a large desktop viewport size (isWide = true) to render layout without overflows
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(DashboardPage), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
