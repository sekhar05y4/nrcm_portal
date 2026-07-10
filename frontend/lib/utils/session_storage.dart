import 'session_storage_stub.dart'
    if (dart.library.html) 'session_storage_web.dart';

class SessionStorage {
  static Future<void> setString(String key, String value) async {
    await saveValue(key, value);
  }

  static Future<String?> getString(String key) async {
    return await getValue(key);
  }

  static Future<void> clear() async {
    await clearSession();
  }
}
