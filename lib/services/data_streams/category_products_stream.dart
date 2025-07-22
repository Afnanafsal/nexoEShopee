import 'package:fishkart/models/Product.dart';
import 'package:fishkart/services/data_streams/data_stream.dart';
import 'package:fishkart/services/database/product_database_helper.dart';

class CategoryProductsStream extends DataStream<List<String>> {
  final ProductType category;

  CategoryProductsStream(this.category) {
    reload();
  }

  @override
  void reload() {
    final allProductsFuture = ProductDatabaseHelper().getCategoryProductsList(
      category,
    );
    allProductsFuture
        .then((favProducts) {
          addData(favProducts);
        })
        .catchError((e) {
          addError(e);
        });
  }
}
