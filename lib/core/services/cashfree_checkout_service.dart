import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:spare_kart/data/models/chat_payment.dart';

class CashfreePaymentResult {
  const CashfreePaymentResult({
    required this.orderId,
  });

  final String orderId;
}

class CashfreeCheckoutService {
  CFPaymentGatewayService? _gateway;
  Completer<CashfreePaymentResult>? _completer;

  Future<CashfreePaymentResult> openCheckout(CashfreeCheckoutSession session) {
    _dispose();
    _gateway = CFPaymentGatewayService();
    _completer = Completer<CashfreePaymentResult>();

    _gateway!.setCallback(_handleSuccess, _handleError);

    try {
      final environment = session.isProduction
          ? CFEnvironment.PRODUCTION
          : CFEnvironment.SANDBOX;
      final cfSession = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(session.orderId)
          .setPaymentSessionId(session.paymentSessionId)
          .build();
      final payment = CFWebCheckoutPaymentBuilder()
          .setSession(cfSession)
          .build();
      _gateway!.doPayment(payment);
    } catch (error) {
      _completeError(error);
    }

    return _completer!.future;
  }

  void _handleSuccess(String orderId) {
    if (orderId.isEmpty) {
      _completeError(const CashfreeCheckoutException('Incomplete payment response'));
      return;
    }

    _completeSuccess(CashfreePaymentResult(orderId: orderId));
  }

  void _handleError(CFErrorResponse errorResponse, String orderId) {
    final message = errorResponse.getMessage() ?? 'Payment failed';
    if (kDebugMode) {
      debugPrint('Cashfree error: $message orderId=$orderId');
    }
    _completeError(CashfreeCheckoutException(message));
  }

  void _completeSuccess(CashfreePaymentResult result) {
    final completer = _completer;
    if (completer == null || completer.isCompleted) return;
    completer.complete(result);
    _dispose();
  }

  void _completeError(Object error) {
    final completer = _completer;
    if (completer == null || completer.isCompleted) return;
    completer.completeError(
      error is CashfreeCheckoutException
          ? error
          : CashfreeCheckoutException(error.toString()),
    );
    _dispose();
  }

  void dispose() => _dispose();

  void _dispose() {
    _gateway = null;
    _completer = null;
  }
}

class CashfreeCheckoutException implements Exception {
  const CashfreeCheckoutException(this.message);
  final String message;

  @override
  String toString() => message;
}
