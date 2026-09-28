import 'package:get/get.dart';
import 'package:otobix/Network/dealer_membership_api.dart';

typedef DealerPageFetcher<T> =
    Future<(List<T> items, bool hasMore)> Function(int page);

class DealerPagedList<T> {
  final DealerPageFetcher<T> fetch;
  final items = <T>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final hasMore = true.obs;
  int _page = 0;

  DealerPagedList(this.fetch);

  Future<void> load({bool reset = false}) async {
    if (isLoading.value || (!reset && !hasMore.value)) return;
    if (reset) {
      _page = 0;
      hasMore.value = true;
      error.value = '';
    }
    isLoading.value = true;
    try {
      final (page, more) = await fetch(_page + 1);
      if (reset) items.clear();
      items.addAll(page);
      _page += 1;
      hasMore.value = more;
    } on DealerApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() => load(reset: true);

  static (List<T>, bool) parse<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final map = Map<String, dynamic>.from(data);
    return (
      (map['items'] as List? ?? [])
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      map['hasMore'] == true,
    );
  }
}
