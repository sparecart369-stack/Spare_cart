import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:spare_kart/data/models/chat_payment.dart';

class RazorpayPaymentResult {
  const RazorpayPaymentResult({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

class RazorpayCheckoutService {
  Razorpay? _razorpay;
  Completer<RazorpayPaymentResult>? _completer;

  Future<RazorpayPaymentResult> openCheckout(RazorpayCheckoutSession session) {
    _dispose();
    _razorpay = Razorpay();
    _completer = Completer<RazorpayPaymentResult>();

    _razorpay!
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final options = <String, dynamic>{
      'key': session.keyId,
      'amount': session.amountPaise,
      'currency': session.currency,
      'name': 'SpareKart',
      'order_id': session.orderId,
      'description': session.description,
      'prefill': {
        'name': session.prefillName,
        'contact': session.prefillContact,
      },
      'theme': {'color': '#2563EB'},
    };

    try {
      _razorpay!.open(options);
    } catch (error) {
      _completeError(error);
    }

    return _completer!.future;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    final orderId = response.orderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';

    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      _completeError(const RazorpayCheckoutException('Incomplete payment response'));
      return;
    }

    _completeSuccess(
      RazorpayPaymentResult(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      ),
    );
  }

  void _handleError(PaymentFailureResponse response) {
    final message = response.message ?? 'Payment failed';
    if (kDebugMode) {
      debugPrint('Razorpay error: $message code=${response.code}');
    }
    _completeError(RazorpayCheckoutException(message));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) {
      debugPrint('Razorpay external wallet: ${response.walletName}');
    }
  }

  void _completeSuccess(RazorpayPaymentResult result) {
    final completer = _completer;
    if (completer == null || completer.isCompleted) return;
    completer.complete(result);
    _dispose();
  }

  void _completeError(Object error) {
    final completer = _completer;
    if (completer == null || completer.isCompleted) return;
    completer.completeError(
      error is RazorpayCheckoutException
          ? error
          : RazorpayCheckoutException(error.toString()),
    );
    _dispose();
  }

  void dispose() => _dispose();

  void _dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _completer = null;
  }
}

class RazorpayCheckoutException implements Exception {
  const RazorpayCheckoutException(this.message);
  final String message;

  @override
  String toString() => message;
}
