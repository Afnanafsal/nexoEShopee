import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpandTextNotifier extends StateNotifier<bool> {
  ExpandTextNotifier() : super(false);

  void toggle() {
    state = !state;
  }

  void setExpanded(bool isExpanded) {
    state = isExpanded;
  }
}

final expandTextProvider = StateNotifierProvider<ExpandTextNotifier, bool>((
  ref,
) {
  return ExpandTextNotifier();
});
