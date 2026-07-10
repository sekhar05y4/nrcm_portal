import 'dart:html' as html;

Future<void> saveValue(String key, String value) async {
  html.window.sessionStorage[key] = value;
}

Future<String?> getValue(String key) async {
  return html.window.sessionStorage[key];
}

Future<void> clearSession() async {
  html.window.sessionStorage.clear();
}
