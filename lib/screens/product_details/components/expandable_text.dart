import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart/providers/product_details_providers.dart';

import '../../../constants.dart';

class ExpandableText extends ConsumerWidget {
  final String title;
  final String content;
  final int maxLines;

  const ExpandableText({
    required Key key,
    required this.title,
    required this.content,
    this.maxLines = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textId = "$title-$content";
    final expandableState = ref.watch(expandableTextProvider(textId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Divider(height: 8, thickness: 1, endIndent: 16),
        Text(
          content,
          maxLines: expandableState.isExpanded ? null : maxLines,
          textAlign: TextAlign.left,
        ),
        GestureDetector(
          onTap: () {
            ref.read(expandableTextProvider(textId).notifier).toggle();
          },
          child: Row(
            children: [
              Text(
                expandableState.isExpanded == false
                    ? "See more details"
                    : "Show less details",
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.arrow_forward_ios, size: 12, color: kPrimaryColor),
            ],
          ),
        ),
      ],
    );
  }
}
