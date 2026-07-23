import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class FirebaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  FirebaseAuthRemoteDataSourceImpl(this.firebaseAuth);

  @override
  Future<UserModel> signUp({required String email, required String password}) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw const AuthException('Sign up failed: User is null');
      }
      return UserModel(
        id: credential.user!.uid,
        email: credential.user!.email ?? email,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'An error occurred during sign up');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw const AuthException('Login failed: User is null');
      }
      return UserModel(
        id: credential.user!.uid,
        email: credential.user!.email ?? email,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'An error occurred during login');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;
      return UserModel(id: user.uid, email: user.email ?? '');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
}

class MockAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SharedPreferences sharedPreferences;
  static const _usersKey = 'mock_auth_users';
  static const _currentUserKey = 'mock_auth_current_user';

  MockAuthRemoteDataSourceImpl(this.sharedPreferences);

  Map<String, String> _getUsers() {
    final raw = sharedPreferences.getString(_usersKey);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUsers(Map<String, String> users) async {
    await sharedPreferences.setString(_usersKey, jsonEncode(users));
  }

  @override
  Future<UserModel> signUp({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email and password cannot be empty');
    }
    
    final users = _getUsers();
    if (users.containsKey(email)) {
      throw const AuthException('The email address is already in use by another account');
    }

    users[email] = password;
    await _saveUsers(users);

    final user = UserModel(
      id: 'mock_uid_${email.hashCode.abs()}',
      email: email,
    );
    await sharedPreferences.setString(_currentUserKey, jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email and password cannot be empty');
    }

    final users = _getUsers();
    if (!users.containsKey(email)) {
      throw const AuthException('No user found matching this email address');
    }

    if (users[email] != password) {
      throw const AuthException('Incorrect password provided for this account');
    }

    final user = UserModel(
      id: 'mock_uid_${email.hashCode.abs()}',
      email: email,
    );
    await sharedPreferences.setString(_currentUserKey, jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 400));
    await sharedPreferences.remove(_currentUserKey);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final raw = sharedPreferences.getString(_currentUserKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
