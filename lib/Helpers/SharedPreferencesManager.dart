import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  static final SharedPreferencesManager _instance =
      SharedPreferencesManager._internal();

  late SharedPreferences _prefs;

  factory SharedPreferencesManager() {
    return _instance;
  }

  SharedPreferencesManager._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<String?> getString(String key) async {
    await init();
    return _prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    await init();
    _prefs.setString(key, value);
  }

  Future<bool?> getBool(String key) async {
    await init();
    return _prefs.getBool(key);
  }

  Future<void> setBool(String key, bool value) async {
    await init();
    _prefs.setBool(key, value);
  }
}
