// lib/widgets/offline_banner.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Network/connectivity_service.dart';

class OfflineBannerWidget extends StatelessWidget {
  const OfflineBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final net = Get.find<ConnectivityService>();
    return Obx(() {
      final show = !net.isOnline.value;
      return IgnorePointer(
        ignoring: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: show ? 28 : 0,
          width: double.infinity,
          color: Colors.red,
          alignment: Alignment.center,
          child:
              show
                  ? const Text(
                    "You're offline. Trying to reconnect…",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  )
                  : const SizedBox.shrink(),
        ),
      );
    });
  }
}
