import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  final SharedPreferences sharedPreferences;

  LocalStorage(this.sharedPreferences);

  String? getString(String key) {
    return sharedPreferences.getString(key);
  }

  Future<bool> setString(String key, String value) {
    return sharedPreferences.setString(key, value);
  }

  Future<bool> remove(String key) {
    return sharedPreferences.remove(key);
  }

  bool containsKey(String key) {
    return sharedPreferences.containsKey(key);
  }
}
