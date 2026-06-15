import 'dart:convert';
import 'dart:io';

import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentSuccessData {
  final String orderId;
  final String paymentId;
  final String signature;

  PaymentSuccessData({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    "razorpay_order_id": orderId,
    "razorpay_payment_id": paymentId,
    "razorpay_signature": signature,
  };
}

class PaymentFailureData {
  final int code;
  final String message;

  PaymentFailureData({required this.code, required this.message});
}

class RazorpayPaymentService {
  Razorpay? _razorpay;

  void init({
    required void Function(PaymentSuccessData success) onSuccess,
    required void Function(PaymentFailureData failure) onFailure,
    required void Function(String walletName) onExternalWallet,
  }) {
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      onSuccess(
        PaymentSuccessData(
          orderId: r.orderId ?? "",
          paymentId: r.paymentId ?? "",
          signature: r.signature ?? "",
        ),
      );
    });

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      onFailure(
        PaymentFailureData(
          code: r.code ?? -1,
          message: _friendlyRazorpayError(r),
        ),
      );
    });

    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      onExternalWallet(r.walletName ?? "");
    });
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  /// ✅ Create order + open checkout
  Future<void> openCheckout({
    required double amountRupees,
    required String name,
    required String description,
    required String customerEmail,
    required String customerPhone,
    required String userId,
    Map<String, dynamic>? notes,
    String? receipt,
  }) async {
    if (_razorpay == null) {
      throw Exception("Payment system not ready. Please try again.");
    }

    try {
      // ✅ 1) Create order on backend
      final resp = await ApiService.post(
        endpoint: AppUrls.createRazorpayOrder,
        body: {
          "appId": AppConstants.appPkgName,
          "appName": AppConstants.appDisplayName,
          "amount": amountRupees,
          "currency": "INR",
          "receipt": receipt,
          "notes": notes ?? {},
          "userId": userId,
        },
      );

      if (resp.statusCode != 200) {
        throw Exception(_friendlyBackendError(resp.body));
      }

      final data = jsonDecode(resp.body);
      final String orderId = (data["orderId"] ?? "").toString();
      final String keyId = (data["keyId"] ?? "").toString();

      if (orderId.isEmpty || keyId.isEmpty) {
        throw Exception("Unable to start payment. Please try again.");
      }

      // ✅ 2) Open Razorpay checkout
      _razorpay!.open({
        "key": keyId,
        "amount": (amountRupees * 100).round(),
        "currency": "INR",
        "name": name,
        "description": description,
        "order_id": orderId,
        "prefill": {"email": customerEmail, "contact": customerPhone},
        "notes": notes ?? {},
        "userId": userId,
      });
    } on SocketException {
      throw Exception("No internet connection. Please check your network.");
    } on FormatException {
      throw Exception("Server error. Please try again in a moment.");
    } catch (e) {
      // fallback
      throw Exception(_friendlyUnknown(e));
    }
  }

  /// ✅ Verify payment on backend (returns false if not verified)
  Future<bool> verifyOnBackend({
    required PaymentSuccessData success,
    String? userId,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final resp = await ApiService.post(
        endpoint: AppUrls.verifyRazorpayPayment,
        body: {
          ...success.toJson(),
          "userId": userId,
          "meta": meta ?? {},
          "appId": AppConstants.appPkgName,
          "appName": AppConstants.appDisplayName,
        },
      );

      if (resp.statusCode != 200) return false;
      final data = jsonDecode(resp.body);
      return data["verified"] == true;
    } on SocketException {
      // network issue: verification failed
      return false;
    } catch (_) {
      return false;
    }
  }

  // -------------------- Friendly error helpers --------------------
  String _friendlyBackendError(String body) {
    // body might be JSON or plain string
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final msg = decoded["message"] ?? decoded["error"] ?? decoded["msg"];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      return "Server error. Please try again.";
    } catch (_) {
      // not JSON
      final s = body.toString();
      if (s.toLowerCase().contains("failed to create order")) {
        return "Unable to create payment order. Please try again.";
      }
      return "Server error. Please try again.";
    }
  }

  String _friendlyUnknown(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains("timeout")) {
      return "Request timed out. Please try again.";
    }
    if (s.contains("host") || s.contains("network")) {
      return "Network issue. Please check internet and try again.";
    }
    return "Something went wrong. Please try again.";
  }

  String _friendlyRazorpayError(PaymentFailureResponse r) {
    // Sometimes response.message is technical
    final raw = (r.message ?? "").toLowerCase();

    // Common user-friendly mapping
    if (raw.contains("cancel")) {
      return "Payment cancelled.";
    }
    if (raw.contains("network")) {
      return "Network issue during payment. Please try again.";
    }
    if (raw.contains("timeout")) {
      return "Payment timed out. Please try again.";
    }
    if (raw.contains("bad request") || raw.contains("invalid")) {
      return "Payment could not be processed. Please try another method.";
    }

    // Code-based fallback (best-effort)
    final code = r.code ?? -1;
    // Many times cancel returns code=2 (common) but not guaranteed.
    // So keep it best-effort + raw text checks already handle it.
    if (code == 2 && raw.contains("cancel")) {
      return "Payment cancelled.";
    }

    // Final fallback (avoid showing raw technical message)
    return "Payment failed. Please try again.";
  }
}
