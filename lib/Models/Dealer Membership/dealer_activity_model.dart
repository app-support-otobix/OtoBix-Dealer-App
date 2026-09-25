import 'package:otobix/Utils/global_functions.dart';

/// One Activity Log entry. [targetType]/[targetId] open the object it is about.
class DealerActivityModel {
  final String id;
  final String module; // BUY | SELL | SERVICES | LEADS | MEMBERSHIP
  final String service;
  final String category;
  final String title;
  final String subtitle;
  final String targetType;
  final String targetId;
  final DateTime? createdAt;

  DealerActivityModel.fromJson(Map<String, dynamic> j)
    : id = GlobalFunctions.parse<String>(j['_id']) ?? '',
      module = GlobalFunctions.parse<String>(j['module']) ?? '',
      service = GlobalFunctions.parse<String>(j['service']) ?? '',
      category = GlobalFunctions.parse<String>(j['category']) ?? '',
      title = GlobalFunctions.parse<String>(j['title']) ?? '',
      subtitle = GlobalFunctions.parse<String>(j['subtitle']) ?? '',
      targetType = GlobalFunctions.parse<String>(j['target']?['type']) ?? '',
      targetId = GlobalFunctions.parse<String>(j['target']?['id']) ?? '',
      createdAt = GlobalFunctions.parse<DateTime>(j['createdAt']);
}
