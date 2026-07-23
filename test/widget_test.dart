import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transient/core/theme/theme_cubit.dart';
import 'package:transient/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient/features/auth/presentation/bloc/auth_event.dart';
import 'package:transient/features/auth/presentation/bloc/auth_state.dart';
import 'package:transient/features/auth/presentation/pages/login_page.dart';
import 'package:transient/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient/features/tasks/presentation/bloc/task_list_state.dart';
import 'package:transient/features/tasks/presentation/pages/dashboard_page.dart';
import 'package:transient/main.dart';

// Simple Mocks for BLoCs to test UI wrapper routing
class FakeThemeCubit extends Cubit<ThemeMode> implements ThemeCubit {
  FakeThemeCubit() : super(ThemeMode.light);

  @override
  void toggleTheme() {}
}

class FakeAuthBloc extends Cubit<AuthState> implements AuthBloc {
  FakeAuthBloc(super.initialState);

  @override
  void add(AuthEvent event) {}
}

class FakeTaskListBloc extends Cubit<TaskListState> implements TaskListBloc {
  FakeTaskListBloc(super.initialState);

  @override
  void add(event) {}
}

void main() {
  late FakeThemeCubit fakeThemeCubit;
  late FakeAuthBloc fakeAuthBloc;
  late FakeTaskListBloc fakeTaskListBloc;

  setUp(() {
    fakeThemeCubit = FakeThemeCubit();
    fakeTaskListBloc = FakeTaskListBloc(const TaskListInitial());
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: fakeThemeCubit),
        BlocProvider<AuthBloc>.value(value: fakeAuthBloc),
        BlocProvider<TaskListBloc>.value(value: fakeTaskListBloc),
      ],
      child: const MaterialApp(home: AuthWrapper()),
    );
  }

  testWidgets('displays Loading Indicator when Auth state is loading', (
    WidgetTester tester,
  ) async {
    fakeAuthBloc = FakeAuthBloc(AuthLoading());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders LoginPage when state is Unauthenticated', (
    WidgetTester tester,
  ) async {
    fakeAuthBloc = FakeAuthBloc(Unauthenticated());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('renders DashboardPage when state is Authenticated', (
    WidgetTester tester,
  ) async {
    fakeAuthBloc = FakeAuthBloc(const Authenticated(user: null));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(DashboardPage), findsOneWidget);
  });
}
