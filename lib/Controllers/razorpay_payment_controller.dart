import 'dart:async';

import 'package:get/get.dart';
import 'package:otobix/Services/razorpay_payment_service.dart';

class RazorpayPaymentController extends GetxController {
  final RazorpayPaymentService _service = RazorpayPaymentService();
  final isPaying = false.obs;

  String? _userId;
  Map<String, dynamic> _meta = {};

  Completer<PaymentSuccessData>? _completer;

  @override
  void onInit() {
    super.onInit();

    _service.init(
      // This will run when payment is successful
      onSuccess: (success) async {
        // verify
        final verified = await _service.verifyOnBackend(
          success: success,
          userId: _userId,
          meta: _meta,
        );

        isPaying.value = false;

        if (verified) {
          _completer?.complete(success);
        } else {
          _completer?.completeError(
            Exception("Payment received but verification failed."),
          );
        }

        _completer = null;
      },
      // This will run when payment is failed
      onFailure: (failure) {
        isPaying.value = false;
        _completer?.completeError(Exception(failure.message));
        _completer = null;
      },
      // This will run when user selects external wallet
      onExternalWallet: (_) {},
    );
  }

  Future<PaymentSuccessData> pay({
    required double amountRupees,
    required String name,
    required String description,
    required String email,
    required String phone,
    required Map<String, dynamic> notes,
    String? receipt,
    String? userId,
    Map<String, dynamic>? meta,
  }) async {
    if (isPaying.value) {
      throw Exception("Payment already in progress.");
    }

    _userId = userId;
    _meta = meta ?? {};

    isPaying.value = true;
    _completer = Completer<PaymentSuccessData>();

    try {
      await _service.openCheckout(
        amountRupees: amountRupees,
        name: name,
        description: description,
        customerEmail: email,
        customerPhone: phone,
        notes: notes,
        receipt: receipt,
        userId: userId ?? "",
      );
      // Razorpay UI opens; result will come via callbacks
      return _completer!.future;
    } catch (e) {
      isPaying.value = false;
      _completer = null;
      final msg = e.toString().replaceAll("Exception: ", "").trim();
      throw Exception(msg);
    }
  }

  @override
  void onClose() {
    _service.dispose();
    super.onClose();
  }
}
