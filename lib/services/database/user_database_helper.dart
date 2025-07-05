import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexoeshopee/models/Address.dart';
import 'package:nexoeshopee/models/CartItem.dart';
import 'package:nexoeshopee/models/OrderedProduct.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';

class UserDatabaseHelper {
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
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await firestore.collection(USERS_COLLECTION_NAME).doc(uid).update(data);
  }

  Future<void> deleteCurrentUserData() async {
    final uid = AuthentificationService().currentUser.uid;
    final docRef = firestore.collection(USERS_COLLECTION_NAME).doc(uid);

    final cartCollectionRef = docRef.collection(CART_COLLECTION_NAME);
    final addressCollectionRef = docRef.collection(ADDRESSES_COLLECTION_NAME);
    final ordersCollectionRef = docRef.collection(
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

    await docRef.delete();
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

  Future<bool> addProductToCart(String productId) async {
    String uid = AuthentificationService().currentUser.uid;
    final docRef = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .doc(productId);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      await docRef.update({CartItem.ITEM_COUNT_KEY: FieldValue.increment(1)});
    } else {
      await docRef.set(CartItem(itemCount: 1).toMap());
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
    await ref.delete();
    return true;
  }

  Future<bool> increaseCartItemCount(String cartItemID) async {
    String uid = AuthentificationService().currentUser.uid;
    final ref = firestore
        .collection(USERS_COLLECTION_NAME)
        .doc(uid)
        .collection(CART_COLLECTION_NAME)
        .doc(cartItemID);
    await ref.update({CartItem.ITEM_COUNT_KEY: FieldValue.increment(1)});
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
    final currentCount = doc.data()?[CartItem.ITEM_COUNT_KEY] ?? 1;
    if (currentCount <= 1) {
      await ref.delete();
    } else {
      await ref.update({CartItem.ITEM_COUNT_KEY: FieldValue.increment(-1)});
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
}
