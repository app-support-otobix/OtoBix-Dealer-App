import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SharedPrefsHelper {
  static const String accessTokenKey = 'accessTokenKey';
  static const String refreshTokenKey = 'refreshTokenKey';
  static const String userKey = 'userKey';
  static const String userIdKey = 'userIdKey';
  static const String userNameKey = 'userNameKey';
  static const String userImageUrlKey = 'userImageUrlKey';
  static const String userRoleKey = 'userRoleKey';
  static const String userApprovalStatusKey = 'userApprovalStatusKey';
  static const String userPhoneNumberKey = 'userPhoneNumberKey';
  static const String userEmailKey = 'userEmailKey';
  static const String entityTypeKey = 'entityTypeKey';
  static const String guestIdKey = 'guestIdKey';

  static late final FlutterSecureStorage _storage;

  /// Call this once at app start (in main())
  static void init() {
    // AndroidOptions ensures the Keystore uses specialized hardware if available
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError:
            true, // Recommended: clears storage gracefully if keys get corrupted
      ),
    );
  }

  /// Save string securely
  static Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Get string securely
  static Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  /// Save boolean securely (converted to string under the hood)
  static Future<void> saveBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  /// Get boolean securely
  static Future<bool> getBool(String key) async {
    String? value = await _storage.read(key: key);
    return value == 'true';
  }

  /// Remove value securely
  static Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all user data (e.g., on logout)
  static Future<void> clearUserData() async {
    // Fetch guest ID
    final String guestId = await getString(guestIdKey) ?? '';

    // Clear all data
    await _storage.deleteAll();

    // Restore guest ID
    if (guestId.isNotEmpty) {
      await saveString(guestIdKey, guestId);
    }
  }

  // static SharedPreferences? _prefs;

  // /// Call this once at app start (like in main())
  // static Future<void> init() async {
  //   _prefs = await SharedPreferences.getInstance();
  // }

  // /// Save string
  // static Future<void> saveString(String key, String value) async {
  //   await _prefs?.setString(key, value);
  // }

  // /// Get string
  // static Future<String?> getString(String key) async {
  //   return _prefs?.getString(key);
  // }

  // /// Save boolean
  // static Future<void> saveBool(String key, bool value) async {
  //   await _prefs?.setBool(key, value);
  // }

  // /// Get boolean
  // static bool getBool(String key) {
  //   return _prefs?.getBool(key) ?? false;
  // }

  // /// Remove value
  // static Future<void> remove(String key) async {
  //   await _prefs?.remove(key);
  // }

  // /// Clear all
  // static Future<void> clearAll() async {
  //   await _prefs?.clear();
  // }
}
