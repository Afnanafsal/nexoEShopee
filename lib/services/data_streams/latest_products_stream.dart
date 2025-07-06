import 'package:nexoeshopee/services/data_streams/data_stream.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';

class LatestProductsStream extends DataStream<List<String>> {
  @override
  void init() {
    reload();
  }

  @override
  void reload() {
    final latestProductsFuture = ProductDatabaseHelper().getLatestProducts(2);
    latestProductsFuture.then((products) {
      addData(products);
    }).catchError((e) {
      addError(e);
    });
  }
}
