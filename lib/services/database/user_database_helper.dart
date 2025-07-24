import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/models/CartItem.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';

class UserDatabaseHelper {
  Future<CartItem?> getCartItemByProductAndAddress(
    String productId,
    String? addressId,
  ) async {
    final uid = AuthentificationService().currentUser.uid;
    final cartRef = FirebaseFirestore.instance
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME);
    final query = cartRef
        .where('product_id', isEqualTo: productId)
        .where('address_id', isEqualTo: addressId);
    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();
      // If CartItem.fromMap expects only the map, pass data
      return CartItem.fromMap(data);
    }
    return null;
  }

  static const String USERS_COLLECTION_NAME = "users";
  static const String ADDRESSES_COLLECTION_NAME = "addresses";
  static const String CART_COLLECTION_NAME = "cart";
  static const String ORDERED_PRODUCTS_COLLECTION_NAME = "ordered_products";

  static const String PHONE_KEY = 'phone';

  static const String DISPLAY_NAME_KEY = "display_name";
  static const String DP_KEY = "display_picture";
  static const String FAV_PRODUCTS_KEY = "favourite_products";

  UserDatabaseHelper._privateConstructor();
  static final UserDatabaseHelper _instance =
      UserDatabaseHelper._privateConstructor();
  factory UserDatabaseHelper() => _instance;

  late final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _firebaseFirestore;

  Future<void> createNewUser(String uid) async {
    await firestore.collection(USERS_COLLECTION_NAME).doc(uid).set({
      DP_KEY: null,
      PHONE_KEY: null,
      FAV_PRODUCTS_KEY: <String>[],
      'usertype': 'customer',
    });
  }

  Future<void> createNewUserWithDisplayName(
    String uid,
    String displayName,
    String phoneNumber,
  ) async {
    await firestore.collection(USERS_COLLECTION_NAME).doc(uid).set({
      DISPLAY_NAME_KEY: displayName,
      PHONE_KEY: phoneNumber,
      DP_KEY: null,
      FAV_PRODUCTS_KEY: <String>[],
      'usertype': 'customer',
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await firestore.collection(USERS_COLLECTION_NAME).doc(uid).update(data);
  }

  Future<void> deleteCurrentUserData() async {
    final uid = AuthentificationService().currentUser.uid;
    final userDocRef = firestore.collection(USERS_COLLECTION_NAME).doc(uid);

    final cartCollectionRef = userDocRef.collection(CART_COLLECTION_NAME);
    final addressCollectionRef = userDocRef.collection(
      ADDRESSES_COLLECTION_NAME,
    );
    final ordersCollectionRef = userDocRef.collection(
      ORDERED_PRODUCTS_COLLECTION_NAME,
    );

    for (final collection in [
      cartCollectionRef,
      addressCollectionRef,
      ordersCollectionRef,
    ]) {
      final docs = await collection.get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }

    await userDocRef.delete();
  }

  Future<bool> isProductFavourite(String productId) async {
    String uid = AuthentificationService().currentUser.uid;
    final userDoc = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .get();
    final favList = List<String>.from(userDoc.data()?[FAV_PRODUCTS_KEY] ?? []);
    return favList.contains(productId);
  }

  Future<List<String>> get usersFavouriteProductsList async {
    String uid = AuthentificationService().currentUser.uid;
    final userDoc = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .get();
    return List<String>.from(userDoc.data()?[FAV_PRODUCTS_KEY] ?? []);
  }

  Future<bool> switchProductFavouriteStatus(
    String productId,
    bool newState,
  ) async {
    String uid = AuthentificationService().currentUser.uid;
    final docRef = firestore.collection(USERS_COLLECTION_NAME).doc(uid);
    if (newState) {
      await docRef.update({
        FAV_PRODUCTS_KEY: FieldValue.arrayUnion([productId]),
      });
    } else {
      await docRef.update({
        FAV_PRODUCTS_KEY: FieldValue.arrayRemove([productId]),
      });
    }
    return true;
  }

  Future<List<String>> get addressesList async {
    String uid = AuthentificationService().currentUser.uid;
    final snapshot = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(ADDRESSES_COLLECTION_NAME)
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<Address> getAddressFromId(String id) async {
    String uid = AuthentificationService().currentUser.uid;
    final doc = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(ADDRESSES_COLLECTION_NAME)
        .doc(id)
        .get();
    final data = doc.data();
    if (data == null) throw Exception("Address not found");
    return Address.fromMap(data, id: doc.id);
  }

  Future<bool> addAddressForCurrentUser(Address address) async {
    String uid = AuthentificationService().currentUser.uid;
    final ref = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(ADDRESSES_COLLECTION_NAME);
    await ref.add(address.toMap());
    return true;
  }

  Future<bool> deleteAddressForCurrentUser(String id) async {
    String uid = AuthentificationService().currentUser.uid;
    final ref = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(ADDRESSES_COLLECTION_NAME)
        .doc(id);
    await ref.delete();
    return true;
  }

  Future<bool> updateAddressForCurrentUser(Address address) async {
    String uid = AuthentificationService().currentUser.uid;
    final ref = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(ADDRESSES_COLLECTION_NAME)
        .doc(address.id);
    await ref.update(address.toMap());
    return true;
  }

  Future<CartItem> getCartItemFromId(String id) async {
    String uid = AuthentificationService().currentUser.uid;
    final doc = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .doc(id)
        .get();
    final data = doc.data();
    if (data == null) throw Exception("Cart item not found");
    return CartItem.fromMap(data, id: doc.id);
  }

  Future<bool> addProductToCart(String productId, {String? addressId}) async {
    String uid = AuthentificationService().currentUser.uid;
    String? effectiveAddressId = addressId;
    if (effectiveAddressId == null) {
      final addresses = await UserDatabaseHelper().addressesList;
      if (addresses.isNotEmpty) {
        effectiveAddressId = addresses.first;
      }
    }
    // Check product stock before adding
    final product = await ProductDatabaseHelper().getProductWithID(productId);
    if (product == null || product.stock == 0) {
      throw Exception('Product is out of stock');
    }
    final compositeId = '${productId}_${effectiveAddressId ?? ""}';
    final docRef = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .doc(compositeId);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      await docRef.update({CartItem.ITEM_COUNT_KEY: FieldValue.increment(1)});
      await Product.reserveStock(productId, 1);
    } else {
      await docRef.set(
        CartItem(
          productId: productId,
          itemCount: 1,
          addressId: effectiveAddressId,
        ).toMap(),
      );
      await Product.reserveStock(productId, 1);
    }
    return true;
  }

  Future<List<String>> emptyCart() async {
    String uid = AuthentificationService().currentUser.uid;
    final snapshot = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .get();
    final productIds = <String>[];
    for (final doc in snapshot.docs) {
      productIds.add(doc.id);
      await doc.reference.delete();
    }
    return productIds;
  }

  Future<num> get cartTotal async {
    String uid = AuthentificationService().currentUser.uid;
    final snapshot = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .get();
    num total = 0;
    for (final doc in snapshot.docs) {
      final itemCount = doc.data()[CartItem.ITEM_COUNT_KEY] ?? 0;
      final product = await ProductDatabaseHelper().getProductWithID(doc.id);
      total += itemCount * ((product?.discountPrice) ?? 0);
    }
    return total;
  }

  Future<bool> removeProductFromCart(String cartItemID) async {
    String uid = AuthentificationService().currentUser.uid;
    final ref = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .doc(cartItemID);
    final doc = await ref.get();
    final productId = doc.data()?[CartItem.PRODUCT_ID_KEY];
    final itemCount = doc.data()?[CartItem.ITEM_COUNT_KEY] ?? 1;
    print('[removeProductFromCart] cartItemID: $cartItemID, productId: $productId, itemCount: $itemCount');
    await ref.delete();
    if (productId != null && itemCount > 0) {
      print('[removeProductFromCart] Restoring stock for productId: $productId, qty: $itemCount');
      await Product.restoreStockFromCart(productId, itemCount);
    }
    return true;
  }

  Future<bool> increaseCartItemCount(String cartItemID) async {
    String uid = AuthentificationService().currentUser.uid;
    final ref = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .doc(cartItemID);
    final doc = await ref.get();
    final productId = doc.data()?[CartItem.PRODUCT_ID_KEY];
    await ref.update({CartItem.ITEM_COUNT_KEY: FieldValue.increment(1)});
    if (productId != null) {
      await Product.reserveStock(productId, 1);
    }
    return true;
  }

  Future<bool> decreaseCartItemCount(String cartItemID) async {
    String uid = AuthentificationService().currentUser.uid;
    final ref = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .doc(cartItemID);
    final doc = await ref.get();
    final productId = doc.data()?[CartItem.PRODUCT_ID_KEY];
    final currentCount = doc.data()?[CartItem.ITEM_COUNT_KEY] ?? 1;
    if (currentCount <= 1) {
      await ref.delete();
      if (productId != null) {
        await Product.unreserveStock(productId, 1);
      }
    } else {
      await ref.update({CartItem.ITEM_COUNT_KEY: FieldValue.increment(-1)});
      if (productId != null) {
        await Product.unreserveStock(productId, 1);
      }
    }
    return true;
  }

  Future<List<String>> get allCartItemsList async {
    String uid = AuthentificationService().currentUser.uid;
    final snapshot = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<String>> get orderedProductsList async {
    String uid = AuthentificationService().currentUser.uid;
    final snapshot = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(ORDERED_PRODUCTS_COLLECTION_NAME)
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<bool> addToMyOrders(List<OrderedProduct> orders) async {
    String uid = AuthentificationService().currentUser.uid;
    final ref = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(ORDERED_PRODUCTS_COLLECTION_NAME);
    for (final order in orders) {
      await ref.add(order.toMap());
    }
    return true;
  }

  Future<OrderedProduct> getOrderedProductFromId(String id) async {
    String uid = AuthentificationService().currentUser.uid;
    final doc = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(ORDERED_PRODUCTS_COLLECTION_NAME)
        .doc(id)
        .get();
    final data = doc.data();
    if (data == null) throw Exception("Order not found");
    return OrderedProduct.fromMap(data, id: doc.id);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get currentUserDataStream {
    final uid = AuthentificationService().currentUser.uid;
    return firestore.collection(USERS_COLLECTION_NAME).doc(uid).snapshots();
  }

  Future<bool> updatePhoneForCurrentUser(String phone) async {
    String uid = AuthentificationService().currentUser.uid;
    await firestore.collection(USERS_COLLECTION_NAME).doc(uid).update({
      PHONE_KEY: phone,
    });
    return true;
  }

  Future<bool> uploadDisplayPictureForCurrentUser(String base64String) async {
    String uid = AuthentificationService().currentUser.uid;
    await firestore.collection(USERS_COLLECTION_NAME).doc(uid).update({
      DP_KEY: base64String,
    });
    return true;
  }

  Future<bool> removeDisplayPictureForCurrentUser() async {
    String uid = AuthentificationService().currentUser.uid;
    await firestore.collection(USERS_COLLECTION_NAME).doc(uid).update({
      DP_KEY: FieldValue.delete(),
    });
    return true;
  }

  Future<String?> get displayPictureForCurrentUser async {
    String uid = AuthentificationService().currentUser.uid;
    final doc = await firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .get();
    return doc.data()?[DP_KEY];
  }

  Future<bool> removeFavoriteProduct(String productId) async {
    String uid = AuthentificationService().currentUser.uid;
    try {
      final userDoc = await firestore
          .collection(USERS_COLLECTION_NAME)
          .doc(uid)
          .get();
      List<dynamic> favList = userDoc.data()?[FAV_PRODUCTS_KEY] ?? [];
      favList.remove(productId);
      await firestore.collection(USERS_COLLECTION_NAME).doc(uid).update({
        FAV_PRODUCTS_KEY: favList,
      });
      return true;
    } catch (e) {
      print("Error removing favorite product: $e");
      return false;
    }
  }
}
