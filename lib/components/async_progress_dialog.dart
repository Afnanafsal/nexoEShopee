import 'package:flutter/material.dart';

/// A custom dialog widget that shows a progress indicator while [future] is being resolved.
/// Automatically closes the dialog when [future] completes or fails.
class AsyncProgressDialog<T> extends StatefulWidget {
  /// The future task to await.
  final Future<T> future;

  /// Box decoration of the dialog container.
  final BoxDecoration? decoration;

  /// Opacity of the dialog content.
  final double opacity;

  /// A custom progress widget (like a loader/spinner).
  final Widget? progress;

  /// An optional message widget to show beside the progress.
  final Widget? message;

  /// Optional error handler callback.
  final void Function(Object error)? onError;

  const AsyncProgressDialog(
    this.future, {
    Key? key,
    this.decoration,
    this.opacity = 1.0,
    this.progress,
    this.message,
    this.onError,
  }) : super(key: key);

  @override
  State<AsyncProgressDialog<T>> createState() => _AsyncProgressDialogState<T>();
}

class _AsyncProgressDialogState<T> extends State<AsyncProgressDialog<T>> {
  @override
  void initState() {
    super.initState();

    widget.future.then((result) {
      Navigator.of(context).pop(result);
    }).catchError((error) {
      Navigator.of(context).pop();
      if (widget.onError != null) {
        widget.onError!(error);
      } else {
        // Optional: show a default error alert or let it crash
        throw error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Opacity(
          opacity: widget.opacity,
          child: _buildDialogContent(),
        ),
      ),
    );
  }

  Widget _buildDialogContent() {
    final BoxDecoration decoration =
        widget.decoration ?? _defaultDecoration;

    if (widget.message == null) {
      return Center(
        child: Container(
          height: 100,
          width: 100,
          alignment: Alignment.center,
          decoration: decoration,
          child: widget.progress ?? const CircularProgressIndicator(),
        ),
      );
    } else {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(20),
        decoration: decoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.progress ?? const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: widget.message!),
          ],
        ),
      );
    }
  }

  BoxDecoration get _defaultDecoration => const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      );
}
