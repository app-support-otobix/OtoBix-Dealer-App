import 'package:intl/intl.dart';

class GlobalFunctions {
  // Parse dynamic value to specific type
  static T? parse<T>(dynamic value) {
    if (value == null) return null;

    // int
    if (T == int) {
      if (value is int) return value as T;
      if (value is double) return value.toInt() as T;
      if (value is String) return int.tryParse(value) as T?;
    }

    // double
    if (T == double) {
      if (value is double) return value as T;
      if (value is int) return value.toDouble() as T;
      if (value is String) return double.tryParse(value) as T?;
    }

    // String
    if (T == String) {
      return value.toString() as T;
    }

    // DateTime
    if (T == DateTime) {
      if (value is DateTime) return value as T;
      if (value is String) return DateTime.tryParse(value) as T?;
    }

    // bool
    if (T == bool) {
      if (value is bool) return value as T;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == '1') return true as T;
        if (lower == 'false' || lower == '0') return false as T;
      }
      if (value is int) return (value == 1) as T;
    }

    // List
    if (T == List) {
      if (value is List) return value as T;
    }

    // Map
    if (T == Map) {
      if (value is Map) return value as T;
    }

    // Fallback
    try {
      return value as T;
    } catch (_) {
      return null;
    }
  }

  // Parse lists
  static List<T> parseList<T>({
    required Type parsedListType,
    required List<dynamic> incomingList,
  }) {
    if (parsedListType == String) {
      return incomingList.map((e) => e.toString() as T).toList();
    }
    if (parsedListType == int) {
      return incomingList.map((e) => int.tryParse(e.toString()) as T).toList();
    }
    if (parsedListType == double) {
      return incomingList
          .map((e) => double.tryParse(e.toString()) as T)
          .toList();
    }
    throw UnsupportedError('Unsupported type: $parsedListType');
  }

  // Parse Date to a specific Format
  static const String year = 'year';
  static const String month = 'month';
  static const String monthName = 'monthname';
  static const String day = 'day';
  static const String weekday = 'weekday';
  static const String time = 'time';
  static const String dateTime = 'datetime';
  static const String clearDateTime = 'cleardatetime';
  static const String fullDate = 'fulldate';
  static const String date = 'date';
  static const String monthYear = 'monthyear';
  static const String dayMonth = 'daymonth';

  static String? getFormattedDate({
    required DateTime? date,
    required String type,
    bool treatAsIndiaLocal = true,
  }) {
    if (date == null) return null;

    // For India-only business dates
    final DateTime indiaDate =
        treatAsIndiaLocal
            ? date.toUtc().add(const Duration(hours: 5, minutes: 30))
            : date.toLocal();

    switch (type.toLowerCase()) {
      case year:
        return DateFormat('yyyy').format(indiaDate);
      case month:
        return DateFormat('MM').format(indiaDate);
      case monthName:
        return DateFormat('MMMM').format(indiaDate);
      case day:
        return DateFormat('dd').format(indiaDate);
      case weekday:
        return DateFormat('EEEE').format(indiaDate);
      case time:
        return DateFormat('hh:mm a').format(indiaDate);
      case dateTime:
        return DateFormat('dd-MM-yyyy hh:mm a').format(indiaDate);
      case clearDateTime:
        return DateFormat('dd MMM yyyy hh:mm a').format(indiaDate);
      case fullDate:
        return DateFormat('dd-MM-yyyy').format(indiaDate);
      case monthYear:
        return DateFormat('MM-yyyy').format(indiaDate);
      case dayMonth:
        return DateFormat('dd-MM').format(indiaDate);
      default:
        return DateFormat('dd-MM-yyyy').format(indiaDate); // fallback
    }
  }

  // =====================================================
  // 💰 Round & format amount to nearest 1000
  // =====================================================
  static T? roundToNearestThousand<T>(dynamic value) {
    if (value == null) return null;

    // Convert to number
    final num? numValue =
        (value is num) ? value : num.tryParse(value.toString());
    if (numValue == null) return null;

    // Round to nearest 1000
    final rounded = ((numValue / 1000).round()) * 1000;

    // Return in requested type
    if (T == int) return rounded.toInt() as T;
    if (T == double) return rounded.toDouble() as T;

    // Fallback
    return rounded as T;
  }

  // Convert UTC to Indian Time (IST)
  static DateTime convertDateTimeToIndianUtc(DateTime utcDateTime) {
    return utcDateTime.add(const Duration(hours: 5, minutes: 30));
  }

  // Convert Indian Time to UTC
  static DateTime convertDateTimeToIndianLocal(DateTime indianDateTime) {
    return indianDateTime.subtract(const Duration(hours: 5, minutes: 30));
  }
}
