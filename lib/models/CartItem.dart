import 'package:nexoeshopee/models/Model.dart';

class CartItem extends Model {
  static const String PRODUCT_ID_KEY = "product_id";
  static const String ITEM_COUNT_KEY = "item_count";

  String? productId;
  int itemCount;

  CartItem({
    String? id,
    this.productId,
    this.itemCount = 0,
  }) : super(id ?? '');

  factory CartItem.fromMap(Map<String, dynamic> map, {String? id}) {
    return CartItem(
      id: id,
      productId: map[PRODUCT_ID_KEY],
      itemCount: map[ITEM_COUNT_KEY] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      PRODUCT_ID_KEY: productId,
      ITEM_COUNT_KEY: itemCount,
    };
  }

  @override
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};

    if (productId != null) map[PRODUCT_ID_KEY] = productId;
    map[ITEM_COUNT_KEY] = itemCount;

    return map;
  }

  CartItem copyWith({
    String? id,
    String? productId,
    int? itemCount,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}
