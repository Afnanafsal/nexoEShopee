import 'package:fishkart/services/data_streams/data_stream.dart';
import 'package:fishkart/services/database/user_database_helper.dart';

class CartItemsStream extends DataStream<List<String>> {
  @override
  void reload() {
    final allProductsFuture = UserDatabaseHelper().allCartItemsList;
    allProductsFuture
        .then((favProducts) {
          addData(favProducts);
        })
        .catchError((e) {
          addError(e);
        });
  }

  void init() {}
}
