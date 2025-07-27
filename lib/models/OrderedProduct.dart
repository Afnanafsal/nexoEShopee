import 'Model.dart';

class OrderedProduct extends Model {
  static const String PRODUCT_UID_KEY = "product_uid";
  static const String ORDER_DATE_KEY = "order_date";
  static const String ADDRESS_ID_KEY = "address_id";
  static const String QUANTITY_KEY = "quantity";
  static const String VENDOR_ID_KEY = "vendor_id";
  static const String USER_ID_KEY = "user_id";
  static const String STATUS_KEY = "status";

  String? productUid;
  String? orderDate;
  String? addressId;
  int quantity;
  String? vendorId;
  String? userId;
  String status;

  OrderedProduct(
    String id, {
    this.productUid,
    this.orderDate,
    this.addressId,
    required this.quantity,
    this.vendorId,
    this.userId,
    this.status = 'pending',
  }) : super(id);

  factory OrderedProduct.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return OrderedProduct(
      id,
      productUid: map[PRODUCT_UID_KEY],
      orderDate: map[ORDER_DATE_KEY],
      addressId: map[ADDRESS_ID_KEY],
      quantity: map[QUANTITY_KEY] ?? 1,
      vendorId: map[VENDOR_ID_KEY],
      userId: id, // userId is the id itself
      status: map[STATUS_KEY] ?? 'pending',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      PRODUCT_UID_KEY: productUid,
      ORDER_DATE_KEY: orderDate,
      ADDRESS_ID_KEY: addressId,
      QUANTITY_KEY: quantity,
      VENDOR_ID_KEY: vendorId,
      USER_ID_KEY: userId,
      STATUS_KEY: status,
    };
  }

  @override
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (productUid != null) map[PRODUCT_UID_KEY] = productUid;
    if (orderDate != null) map[ORDER_DATE_KEY] = orderDate;
    if (addressId != null) map[ADDRESS_ID_KEY] = addressId;
    map[QUANTITY_KEY] = quantity;
    if (vendorId != null) map[VENDOR_ID_KEY] = vendorId;
    if (userId != null) map[USER_ID_KEY] = userId;
    map[STATUS_KEY] = status;
    return map;
  }

  OrderedProduct copyWith({
    String? id,
    String? productUid,
    String? orderDate,
    String? addressId,
    int? quantity,
    String? vendorId,
    String? userId,
    String? status,
  }) {
    return OrderedProduct(
      (id ?? this.id),
      productUid: productUid ?? this.productUid,
      orderDate: orderDate ?? this.orderDate,
      addressId: addressId ?? this.addressId,
      quantity: quantity ?? this.quantity,
      vendorId: vendorId ?? this.vendorId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
    );
  }
}
