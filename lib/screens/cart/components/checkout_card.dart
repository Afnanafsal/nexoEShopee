import 'package:fishkart/components/default_button.dart';
import 'package:flutter/material.dart';

import '../../../size_config.dart';

class CheckoutCard extends StatefulWidget {
  final VoidCallback onCheckoutPressed;
  final VoidCallback onRazorpayPressed;
  final double totalPrice;
  const CheckoutCard({
    required this.onCheckoutPressed,
    required this.onRazorpayPressed,
    required this.totalPrice,
    super.key,
  });

  @override
  State<CheckoutCard> createState() => _CheckoutCardState();
}

class _CheckoutCardState extends State<CheckoutCard> {
  bool _visible = true;

  void _handleNormalCheckout() {
    setState(() => _visible = false);
    widget.onCheckoutPressed();
  }

  void _handleRazorpayCheckout() {
    setState(() => _visible = false);
    widget.onRazorpayPressed();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: getProportionateScreenHeight(20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    text: "Total\n",
                    children: [
                      TextSpan(
                        text: "₹${widget.totalPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: getProportionateScreenHeight(20)),
            DefaultButton(
              text: "Checkout",
              press: _handleNormalCheckout,
            ),
            SizedBox(height: getProportionateScreenHeight(10)),
            DefaultButton(
              text: "Checkout with Razorpay",
              press: _handleRazorpayCheckout,
              color: Colors.black,
            ),
            SizedBox(height: getProportionateScreenHeight(10)),
          ],
        ),
      ),
    );
  }
}
