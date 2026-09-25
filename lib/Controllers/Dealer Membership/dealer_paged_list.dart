import 'package:get/get.dart';
import 'package:otobix/Network/dealer_membership_api.dart';

/// One page of results from a `{ items, hasMore }` Dealer Membership list API.
typedef DealerPageFetcher<T> =
    Future<(List<T> items, bool hasMore)> Function(int page);

/// Reactive paged list shared by every Dealer Membership list screen:
/// loading / error / has-more state and "load the next page" in one place.
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

  /// Parses a `{ items, hasMore }` payload with [fromJson].
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
