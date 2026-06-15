import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/registration_form_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsAndConditionsBottomSheetWidget extends StatefulWidget {
  final String title;
  final String html;
  final VoidCallback onAgree;

  const TermsAndConditionsBottomSheetWidget({
    required this.title,
    required this.html,
    required this.onAgree,
    super.key,
  });

  @override
  State<TermsAndConditionsBottomSheetWidget> createState() =>
      TermsAndConditionsBottomSheetWidgetState();
}

class TermsAndConditionsBottomSheetWidgetState
    extends State<TermsAndConditionsBottomSheetWidget> {
  bool _agreed = false;
  late final WebViewController _webController;
  final RegistrationFormController getxController =
      Get.find<RegistrationFormController>();

  @override
  void initState() {
    super.initState();
    _webController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(
            Uri.dataFromString(
              _wrapHtml(widget.html),
              mimeType: 'text/html',
              encoding: utf8,
            ),
          );
  }

  String _wrapHtml(String body) {
    return '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
  body { font-family: -apple-system, Roboto, Arial, sans-serif; padding: 12px; line-height: 1.5; }
  h1,h2,h3 { margin: 0.6em 0 0.4em; }
  p, li { font-size: 14px; }
</style>
</head>
<body>$body</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.86; // tall, but not full-screen

    return GestureDetector(
      onTap: () {}, // let taps fall through only inside sheet
      child: Container(
        color: Colors.transparent, // keep rounded corners visible
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            elevation: 12,
            color: theme.dialogTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: sheetHeight,
                child: Column(
                  children: [
                    // grab handle
                    const SizedBox(height: 15),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              // widget.title.isNotEmpty ? widget.title : 'Terms & Conditions',
                              'Terms & Conditions',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 3),
                    const Divider(height: 1),

                    // WebView
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: WebViewWidget(controller: _webController),
                        ),
                      ),
                    ),

                    // Agree row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            activeColor: AppColors.green,
                            checkColor: AppColors.white,
                            value: _agreed,
                            onChanged:
                                (v) => setState(() => _agreed = v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Terms & Conditions',
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ButtonWidget(
                              text: 'Agree & Submit',
                              isLoading: getxController.isLoading,

                              onTap:
                                  _agreed
                                      ? () {
                                        Navigator.of(context).maybePop();
                                        widget.onAgree();
                                      }
                                      : () {},
                              height: 40,
                              width: 150,
                              backgroundColor:
                                  _agreed
                                      ? AppColors.green
                                      : AppColors.grey.withValues(alpha: 0.2),
                              textColor:
                                  _agreed ? AppColors.white : AppColors.grey,
                              loaderSize: 15,
                              loaderStrokeWidth: 1,
                              loaderColor: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
