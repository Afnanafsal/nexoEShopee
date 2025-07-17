import 'package:flutter/material.dart';

class TopRoundedContainer extends StatelessWidget {
  final Color color;
  final Widget child;
  const TopRoundedContainer({
    required Key key,
    this.color = Colors.transparent,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container( child: child);
  }
}
