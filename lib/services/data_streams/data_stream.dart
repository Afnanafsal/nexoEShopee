import 'dart:async';

abstract class DataStream<T> {
  final StreamController<T> streamController = StreamController<T>();

  /// Expose the stream
  Stream<T> get stream => streamController.stream;

  /// Add data to stream
  void addData(T data) {
    streamController.sink.add(data);
  }

  /// Add error to stream
  void addError(dynamic error) {
    streamController.sink.addError(error);
  }

  /// Override this to fetch/reload data
  void reload();

  /// Dispose the stream when done
  void dispose() {
    streamController.close();
  }
}
