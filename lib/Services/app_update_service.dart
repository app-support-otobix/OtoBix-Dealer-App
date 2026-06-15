import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/app_update_info_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum _UpdateType { none, optional, required }

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  bool _dialogShowing = false;

  /// Call this on app launch (after runApp / first frame is safest).
  Future<void> checkOnLaunch({required String appKey}) async {
    try {
      // 1) Fetch remote config
      final remote = await _fetchRemote(appKey: appKey);
      if (remote == null) return;

      // If admin disabled updates globally, do nothing
      if (remote.enabled != true) return;

      // 2) Determine platform config
      final PlatformType platformConfig;
      if (Platform.isAndroid) {
        platformConfig = remote.android;
      } else if (Platform.isIOS) {
        platformConfig = remote.ios;
      } else {
        // desktop/web etc → skip
        return;
      }

      // 3) Get installed app version
      final pkg = await PackageInfo.fromPlatform();
      final currentVersion = (pkg.version).trim();

      final minV = platformConfig.minSupportedVersion.trim();
      final latestV = platformConfig.latestVersion.trim();

      if (currentVersion.isEmpty || minV.isEmpty || latestV.isEmpty) return;

      // 4) Decide update type
      final type = _decide(
        current: currentVersion,
        minSupported: minV,
        latest: latestV,
      );

      if (type == _UpdateType.none) return;

      // 5) Decide store url
      final storeUrl = _getStoreUrl(platformConfig: platformConfig);

      if (storeUrl == null || storeUrl.isEmpty) return;

      // 6) Show dialog safely after frame (no deadlock)
      _showUpdateDialogSafely(
        type: type,
        currentVersion: currentVersion,
        latestVersion: latestV,
        minSupportedVersion: minV,
        releaseNotes: platformConfig.releaseNotes,
        storeUrl: storeUrl,
      );
    } catch (_) {
      // Important: never block app start with update check errors
      return;
    }
  }

  Future<AppUpdateInfoModel?> _fetchRemote({required String appKey}) async {
    try {
      // Your endpoint helper:
      final url = AppUrls.getAppUpdateInfo(appKey: appKey);

      final res = await ApiService.get(endpoint: url);

      if (res.statusCode != 200) return null;

      // expected: { success: true, data: {...} }
      final decoded =
          jsonDecode(res.body)
              as Map<String, dynamic>; // if you don't have decode helper
      // If you have decode helper, replace with:
      // final decoded = ApiService.jsonDecode(res.body);

      final data = decoded["data"];
      if (data == null || data is! Map<String, dynamic>) return null;

      return AppUpdateInfoModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  _UpdateType _decide({
    required String current,
    required String minSupported,
    required String latest,
  }) {
    final cVsMin = _compareVersions(current, minSupported);
    if (cVsMin < 0) return _UpdateType.required;

    final cVsLatest = _compareVersions(current, latest);
    if (cVsLatest < 0) return _UpdateType.optional;

    return _UpdateType.none;
  }

  /// Returns -1 if a<b, 0 if equal, 1 if a>b
  int _compareVersions(String a, String b) {
    // Handles "1.2.3" and also "1.2.3+4" / "1.2.3-beta" by ignoring suffixes
    String clean(String v) {
      var s = v.trim();
      // remove build metadata
      final plus = s.indexOf('+');
      if (plus != -1) s = s.substring(0, plus);
      // remove pre-release suffix
      final dash = s.indexOf('-');
      if (dash != -1) s = s.substring(0, dash);
      return s;
    }

    final aa = clean(a).split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bb = clean(b).split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final len = aa.length > bb.length ? aa.length : bb.length;
    while (aa.length < len) aa.add(0);
    while (bb.length < len) bb.add(0);

    for (int i = 0; i < len; i++) {
      if (aa[i] < bb[i]) return -1;
      if (aa[i] > bb[i]) return 1;
    }
    return 0;
  }

  String? _getStoreUrl({required PlatformType platformConfig}) {
    final url = platformConfig.storeUrl.trim();
    if (url.isNotEmpty) return url;

    // fallback for Android if storeUrl is empty
    if (Platform.isAndroid) {
      final pkg = platformConfig.packageName.trim();
      if (pkg.isEmpty) return null;
      return "https://play.google.com/store/apps/details?id=$pkg";
    }

    // iOS fallback is not reliable without App Store ID → require storeUrl
    return null;
  }

  void _showUpdateDialogSafely({
    required _UpdateType type,
    required String currentVersion,
    required String latestVersion,
    required String minSupportedVersion,
    required String releaseNotes,
    required String storeUrl,
  }) {
    if (_dialogShowing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final ctx = Get.key.currentContext;
        if (ctx == null) return;
        if (_dialogShowing) return;

        _dialogShowing = true;

        final isRequired = type == _UpdateType.required;

        await showDialog(
          context: ctx,
          barrierDismissible: !isRequired,
          builder:
              (_) => _UpdateDialog(
                requiredUpdate: isRequired,
                currentVersion: currentVersion,
                latestVersion: latestVersion,
                minSupportedVersion: minSupportedVersion,
                releaseNotes: releaseNotes,
                onUpdate: () => _openStore(storeUrl),
              ),
        );

        _dialogShowing = false;
      } catch (_) {
        _dialogShowing = false;
        return;
      }
    });
  }

  Future<void> _openStore(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // ignore, never block app
    }
  }
}

class _UpdateDialog extends StatelessWidget {
  final bool requiredUpdate;
  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String releaseNotes;
  final Future<void> Function() onUpdate;

  const _UpdateDialog({
    required this.requiredUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.releaseNotes,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final title = requiredUpdate ? "Update Required" : "Update Available";

    final message =
        requiredUpdate
            ? "Your app version ($currentVersion) is no longer supported.\nPlease update to continue using the app."
            : "A newer version ($latestVersion) is available.\nYou’re currently on $currentVersion.";

    final notes = releaseNotes.trim();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Icon(
            requiredUpdate ? Icons.warning_rounded : Icons.system_update_alt,
            color: requiredUpdate ? AppColors.red : AppColors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 14),
            _InfoRow(label: "Latest", value: latestVersion),
            _InfoRow(label: "Minimum Supported", value: minSupportedVersion),
            const SizedBox(height: 14),
            if (notes.isNotEmpty) ...[
              const Text(
                "What’s new",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 50,
                  maxHeight: 100,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Expanded(child: SingleChildScrollView(child: Text(notes))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!requiredUpdate)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Later", style: TextStyle(color: AppColors.blue)),
          ),

        ButtonWidget(
          text: requiredUpdate ? "Update Now" : "Update",
          isLoading: false.obs,
          elevation: 5,
          height: 35,
          width: 130,
          fontSize: 12,

          backgroundColor: Colors.green.shade600,
          onTap: () async {
            await onUpdate();
            // For required update, don’t auto-close (user might come back)
            // For optional update, you can close:
            if (!requiredUpdate) {
              if (context.mounted) Navigator.of(context).pop();
            }
          },
        ),
        // ElevatedButton(
        //   onPressed: () async {
        //     await onUpdate();
        //     // For required update, don’t auto-close (user might come back)
        //     // For optional update, you can close:
        //     if (!requiredUpdate) {
        //       if (context.mounted) Navigator.of(context).pop();
        //     }
        //   },
        //   child: Text(requiredUpdate ? "Update Now" : "Update"),
        // ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
