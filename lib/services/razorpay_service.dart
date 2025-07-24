import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required double amount,
    required String name,
    required String description,
    required String contact,
    required String email,
  }) {
    var options = {
      'key': 'RAZORPAY_API_KEY', // TODO: Replace with your API key
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': name,
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'external': {'wallets': ['paytm']}
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    // TODO: Handle success (e.g., update backend, show confirmation)
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} | ${response.message}');
    // TODO: Handle error (e.g., show error message)
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    // TODO: Handle external wallet
  }

  void dispose() {
    _razorpay.clear();
  }
}
