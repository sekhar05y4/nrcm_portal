// Memory fallback for mobile platforms
final Map<String, String> _memStorage = {};

Future<void> saveValue(String key, String value) async {
  _memStorage[key] = value;
}

Future<String?> getValue(String key) async {
  return _memStorage[key];
}

Future<void> clearSession() async {
  _memStorage.clear();
}
