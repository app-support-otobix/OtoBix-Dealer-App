// lib/services/auction_countdowns.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AuctionCountdownForNotificationCar extends GetxService {
  final RxMap<String, RxString> times = <String, RxString>{}.obs;
  final Map<String, Timer> _timers = {};
  final Map<String, List<VoidCallback>> _endListeners = {};

  RxString timeFor(String carId) => times.putIfAbsent(carId, () => ''.obs);

  void onEnd(String carId, VoidCallback cb) {
    _endListeners.putIfAbsent(carId, () => []).add(cb);
  }

  void removeOnEnd(String carId, VoidCallback cb) {
    final list = _endListeners[carId];
    list?.remove(cb);
    if (list != null && list.isEmpty) _endListeners.remove(carId);
  }

  void _emitEnd(String carId) {
    final list = _endListeners.remove(carId);
    if (list != null) {
      for (final cb in List<VoidCallback>.from(list)) {
        try {
          cb();
        } catch (_) {}
      }
    }
  }

  void start(String carId, DateTime endAt) {
    cancel(carId);

    String _fmt(Duration d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.inHours)}h : ${two(d.inMinutes % 60)}m : ${two(d.inSeconds % 60)}s';
    }

    void _write(String s) => timeFor(carId).value = s;

    void tick() {
      final diff = endAt.difference(DateTime.now());
      if (diff.isNegative || diff.inSeconds <= 0) {
        _write('00h : 00m : 00s');
        cancel(carId);
        _emitEnd(carId);
        return;
      }
      _write(_fmt(diff));
    }

    tick();
    _timers[carId] = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// NEW: Start using an ISO8601 string (UTC or with offset).
  /// Returns `false` if parsing failed or end is in the past.
  bool startFromIso(String carId, String? iso) {
    if (iso == null || iso.isEmpty) return false;
    final endAt = DateTime.tryParse(iso)?.toLocal();
    if (endAt == null) return false;
    if (!endAt.isAfter(DateTime.now())) return false;
    start(carId, endAt);
    return true;
  }

  void startForSeconds(String carId, int secondsFromNow) {
    start(carId, DateTime.now().add(Duration(seconds: secondsFromNow)));
  }

  void applyNewEnd(String carId, DateTime newEndAt) {
    start(carId, newEndAt);
  }

  void cancel(String carId) {
    _timers[carId]?.cancel();
    _timers.remove(carId);
  }

  @override
  void onClose() {
    for (final t in _timers.values) t.cancel();
    _timers.clear();
    _endListeners.clear();
    super.onClose();
  }
}
