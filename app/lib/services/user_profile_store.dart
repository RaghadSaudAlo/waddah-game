import 'package:shared_preferences/shared_preferences.dart';

class UserProfileStore {
  static Future<void> saveUser({
    required String username,
    required String email,
    required int age,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setInt('age', age);
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  static Future<int> getAge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('age') ?? 6;
  }
}