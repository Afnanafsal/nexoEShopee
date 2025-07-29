import 'package:flutter/material.dart';
import '../services/razorpay_service.dart';

class CheckoutButton extends StatefulWidget {
  final double amount;
  final String name;
  final String description;
  final String contact;
  final String email;

  const CheckoutButton({
    super.key,
    required this.amount,
    required this.name,
    required this.description,
    required this.contact,
    required this.email,
  });

  @override
  State<CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends State<CheckoutButton> {
  late RazorpayService _razorpayService;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _onCheckoutPressed() {
    _razorpayService.openCheckout(
      amount: widget.amount,
      name: widget.name,
      description: widget.description,
      contact: widget.contact,
      email: widget.email,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _onCheckoutPressed,
      child: const Text('Checkout with Razorpay'),
    );
  }
}

// Usage Example:
// CheckoutButton(
//   amount: 100.0,
//   name: 'NexoEShopee',
//   description: 'Order Payment',
//   contact: '9876543210',
//   email: 'user@example.com',
// )
