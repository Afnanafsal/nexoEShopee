import 'dart:async';

abstract class DataStream<T> {
  final StreamController<T> streamController = StreamController<T>.broadcast();

  Stream<T> get stream => streamController.stream;

  void addData(T data) {
    streamController.sink.add(data);
  }

  void addError(dynamic error) {
    streamController.sink.addError(error);
  }

  void reload();

  void dispose() {
    streamController.close();
  }
}
