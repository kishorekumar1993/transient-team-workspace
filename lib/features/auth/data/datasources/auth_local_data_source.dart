import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCachedUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _cachedUserKey = 'cached_auth_user';

  AuthLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<UserModel?> getCachedUser() async {
    final raw = sharedPreferences.getString(_cachedUserKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      throw const CacheException('Failed to read cached user');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final success = await sharedPreferences.setString(_cachedUserKey, jsonEncode(user.toJson()));
    if (!success) {
      throw const CacheException('Failed to cache user session');
    }
  }

  @override
  Future<void> clearCachedUser() async {
    final success = await sharedPreferences.remove(_cachedUserKey);
    if (!success) {
      throw const CacheException('Failed to clear cached user session');
    }
  }
}
