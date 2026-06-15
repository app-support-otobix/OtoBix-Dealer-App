import 'dart:convert';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_urls.dart';

class TermsAndConditionsController extends GetxController {
  final isLoading = true.obs;
  final error = RxnString();
  final title = 'Terms & Conditions'.obs;

  late final WebViewController webController;

  @override
  void onInit() {
    super.onInit();
    webController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest navigation) async {
                // Check for external links, mailto or other special cases
                if (await _canLaunch(navigation.url)) {
                  await _launchUrl(navigation.url);
                  return NavigationDecision
                      .prevent; // Prevent loading in the WebView
                }
                return NavigationDecision
                    .navigate; // Allow loading within WebView
              },
            ),
          );
    fetchLatest();
  }

  // Fetch latest terms and conditions
  Future<void> fetchLatest() async {
    try {
      isLoading.value = true;
      error.value = null;

      final resp = await ApiService.get(
        endpoint: AppUrls.getLatestTermsAndConditions,
      );

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = parsed['data'] as Map<String, dynamic>?;
        final html = (data?['content'] as String?)?.trim() ?? '';
        final apiTitle = (data?['title'] as String?)?.trim();

        if (apiTitle != null && apiTitle.isNotEmpty) {
          title.value = apiTitle;
        }

        if (html.isEmpty) {
          error.value = 'No terms available.';
        } else {
          await webController.loadRequest(
            Uri.dataFromString(
              _wrapHtml(html),
              mimeType: 'text/html',
              encoding: utf8,
            ),
          );
        }
      } else {
        error.value = 'Failed to load terms (${resp.statusCode}).';
      }
    } catch (e) {
      error.value = 'Failed to load terms.';
    } finally {
      isLoading.value = false;
    }
  }

  // Reload terms and conditions
  void reload() => fetchLatest();

  // Wrap HTML content
  String _wrapHtml(String body) {
    // Replace all http:// links with https://
    body = body.replaceAll('http://', 'https://');
    return '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
  body { font-family: -apple-system, Roboto, Arial, sans-serif; padding: 16px; line-height: 1.6; color:#222; }
  h1,h2,h3 { margin: 0.8em 0 0.4em; }
  p, li { font-size: 15px; }
  a { color: #0A84FF; }
</style>
</head>
<body>$body</body>
</html>
''';
  }

  // Helper to check if URL can be launched
  Future<bool> _canLaunch(String url) async {
    return await canLaunchUrl(Uri.parse(url));
  }

  // Helper to launch URL in external browser
  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}
