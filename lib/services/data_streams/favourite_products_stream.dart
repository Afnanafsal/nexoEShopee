import 'package:fishkart/services/data_streams/data_stream.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/database/user_database_helper.dart';

class FavouriteProductsStream extends DataStream<List<String>> {
  @override
  void init() {
    reload();
  }

  @override
  void reload() {
    final favProductsFuture = UserDatabaseHelper().usersFavouriteProductsList;
    favProductsFuture
        .then((favProducts) {
          addData(favProducts.cast<String>());
        })
        .catchError((e) {
          addError(e);
        });
  }
}
