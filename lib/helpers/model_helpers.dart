import 'package:otobix/Utils/global_functions.dart';

class ModelHelpers {
  ModelHelpers._();

  // ==================== FROM JSON (READING) ====================

  /// Safely get String from JSON
  static String getString(
    Map<String, dynamic>? json,
    String key, {
    String defaultValue = '',
  }) {
    if (json == null) return defaultValue;
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    } catch (e) {
      return defaultValue;
    }
  }

  /// Safely get int from JSON
  static int getInt(
    Map<String, dynamic>? json,
    String key, {
    int defaultValue = 0,
  }) {
    if (json == null) return defaultValue;
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is bool) return value ? 1 : 0;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Safely get double from JSON
  static double getDouble(
    Map<String, dynamic>? json,
    String key, {
    double defaultValue = 0.0,
  }) {
    if (json == null) return defaultValue;
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Safely get bool from JSON
  static bool getBool(
    Map<String, dynamic>? json,
    String key, {
    bool defaultValue = false,
  }) {
    if (json == null) return defaultValue;
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Safely get DateTime from JSON (with Indian timezone)
  static DateTime? getDateTime(Map<String, dynamic>? json, String key) {
    if (json == null) return null;
    try {
      final value = json[key];
      if (value == null) return null;

      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return GlobalFunctions.convertDateTimeToIndianLocal(parsed);
        }
        return null;
      }
      if (value is int) {
        return GlobalFunctions.convertDateTimeToIndianLocal(
          DateTime.fromMillisecondsSinceEpoch(value),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== TO JSON (WRITING) ====================

  /// Add to map if value is not null
  static void addIfNotNull(
    Map<String, dynamic> map,
    String key,
    dynamic value,
  ) {
    if (value != null) {
      map[key] = value;
    }
  }

  /// Add DateTime to map (converts to UTC for storage)
  static void addDateTime(
    Map<String, dynamic> map,
    String key,
    DateTime? value,
  ) {
    if (value != null) {
      final utcDateTime = GlobalFunctions.convertDateTimeToIndianUtc(value);
      map[key] = utcDateTime.toIso8601String();
    }
  }
}
