// lib/services/connectivity_service.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService extends GetxService {
  final RxBool isOnline = true.obs;

  // v3+ uses a singleton instance (no unnamed constructor)
  final InternetConnectionChecker _checker = InternetConnectionChecker.instance;

  StreamSubscription<List<ConnectivityResult>>? _connSub; // v6 streams a *List*

  Future<ConnectivityService> init() async {
    await _recheck();
    _connSub = Connectivity().onConnectivityChanged.listen((results) async {
      await _recheck(results);
    });
    return this;
  }

  Future<void> _recheck([List<ConnectivityResult>? cached]) async {
    final results = cached ?? await Connectivity().checkConnectivity();
    final hasNetwork =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (!hasNetwork) {
      isOnline.value = false;
      return;
    }
    // verify actual internet reachability
    isOnline.value = await _checker.hasConnection;
  }

  /// Re-check and return true if online; false otherwise.
  Future<bool> ensureOnline() async {
    await _recheck();
    return isOnline.value;
  }

  Stream<bool> get onStatusChanged => isOnline.stream;

  @override
  void onClose() {
    _connSub?.cancel();
    super.onClose();
  }
}
