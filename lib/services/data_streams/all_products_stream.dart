import 'package:fishkart/services/data_streams/data_stream.dart';
import 'package:fishkart/services/database/product_database_helper.dart';

class AllProductsStream extends DataStream<List<String>> {
  @override
  void init() {
    reload();
  }

  @override
  void reload() {
    final allProductsFuture = ProductDatabaseHelper().getAllProducts();
    allProductsFuture
        .then((products) {
          addData(products);
        })
        .catchError((e) {
          addError(e);
        });
  }
}
