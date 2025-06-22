import 'Model.dart';

class OrderedProduct extends Model {
  static const String PRODUCT_UID_KEY = "product_uid";
  static const String ORDER_DATE_KEY = "order_date";

  String? productUid;
  String? orderDate;

  OrderedProduct(
    String id, {
    this.productUid,
    this.orderDate,
  }) : super(id);

  factory OrderedProduct.fromMap(Map<String, dynamic> map, {required String id}) {
    return OrderedProduct(
      id,
      productUid: map[PRODUCT_UID_KEY],
      orderDate: map[ORDER_DATE_KEY],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      PRODUCT_UID_KEY: productUid,
      ORDER_DATE_KEY: orderDate,
    };
  }

  @override
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (productUid != null) map[PRODUCT_UID_KEY] = productUid;
    if (orderDate != null) map[ORDER_DATE_KEY] = orderDate;
    return map;
  }

  OrderedProduct copyWith({
    String? id,
    String? productUid,
    String? orderDate,
  }) {
    return OrderedProduct(
      (id ?? this.id),
      productUid: productUid ?? this.productUid,
      orderDate: orderDate ?? this.orderDate,
    );
  }
}
