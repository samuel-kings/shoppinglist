import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:ez_localization/ez_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';
import 'package:shoppinglist/consts/category_list.dart';
import 'package:shoppinglist/consts/notif_keys.dart';
import 'package:shoppinglist/helpers/utils/id_gen.dart';
import 'package:shoppinglist/helpers/utils/sec_storage.dart';
import 'package:shoppinglist/helpers/widgets/snackbar_helper.dart';
import 'package:shoppinglist/models/family.dart';
import 'package:shoppinglist/models/user.dart';
import 'package:shoppinglist/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:shoppinglist/providers/notification_provider.dart';
import '../consts/prefs_consts.dart';
import '../models/category.dart';
import '../models/product.dart';

/// Instance of local database
final db = Localstore.instance;

class ShoppingListsProvider extends ChangeNotifier {
  // Error message of last executed method
  String _error = "";
  List<Product> _searchRes = [];
  List<Product> _shoppingList = [];
  bool _isFiltered = false;
  List<Category> _categories = [];
  bool _isSearching = false;
  bool _isGettingList = true;

  /// Instance of Firebase DB
  final _dbRef = FirebaseDatabase.instance.ref();

  /// Shopping list coolection instance in local storage
  final _shoppingListColl = db.collection(PrefsConsts.shoppingList);

  /// Category list coolection instance in local storage
  final _categoryListColl = db.collection(PrefsConsts.categoryList);

  /// Error message of last executed method
  String get error => _error;

  /// List of products/items from search results
  List<Product> get searchRes => _searchRes;

  /// List of products in the family's shopping list
  List<Product> get shoppingList => _shoppingList;

  /// Indicates if checked/ddone items are the shopping list are hidden or shown
  bool get isFiltered => _isFiltered;

  /// Is true when a search operation is ongoing. This is used to display a loading widget during the process
  bool get isSearching => _isSearching;

  /// Is true when the categories and shopping lists are being loaded for the first time after app launch.
  /// This is also used to display a loading animation when true
  bool get isGettingList => _isGettingList;

  /// List of family shopping list categories
  List<Category> get categories => _categories;

  /// On new account creation, create family data in Firebase and add default categories,
  /// then caches data.
  /// Returns an error message if error occured and null if successful
  Future<String?> createListsOnAcctCreation(Family family) async {
    try {
      // upload family
      _dbRef.child(family.id).child(PrefsConsts.family).set(family.toMap());

      // upload categoryList
      for (var element in categoryList.entries) {
        Category category = Category(id: id(element.key), name: element.key, products: [], isCustomCategory: false);
        List<String> products = [];
        for (var product in element.value) {
          products.add(product);
        }
        category.products = products;

        _dbRef.child(family.id).child(PrefsConsts.categoryList).child(category.id).set(category.toMap());
      }

      // get categoryList from DB
      final res = await _dbRef.child(family.id).child(PrefsConsts.categoryList).once();
      final values = res.snapshot.value;
      if (values != null) {
        Map values_ = values as Map;
        _categories = values_.entries.map((e) {
          Map<Object?, Object?> map = e.value;
          Map<String, dynamic> temp = Map.castFrom(map);
          return Category.fromMap(temp);
        }).toList();
      }

      // save categoryList to local
      for (var cat in _categories) {
        _categoryListColl.doc(cat.id).set(cat.toMap());
      }

      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      return _error;
    }
  }

  /// Get shopping list and category list
  /// Returns an error message if error occured and null if successful
  Future<String?> getLists(BuildContext context, String familyId) async {
    try {
      // get user
      final userString = await secStorage.read(key: PrefsConsts.user);
      User user = User.fromJson(userString!);

      // get notifiedIds
      final idsString = await secStorage.read(key: PrefsConsts.notifiedIds);
      List<String> ids = [];
      if (idsString != null) ids = idsString.split(",");

      // get lists from local db
      final shopping = await _shoppingListColl.get();
      final cats = await _categoryListColl.get();
      if (shopping != null) _shoppingList = shopping.values.map((e) => Product.fromMap(e)).toList();
      if (cats != null) _categories = cats.values.map((e) => Category.fromMap(e)).toList();
      if (shopping != null || cats != null) _isGettingList = false;
      notifyListeners();

      // get categoryList
      final res = await _dbRef.child(familyId).child(PrefsConsts.categoryList).once();
      final values = res.snapshot.value;
      if (values != null) {
        // clear local db
        for (var cat in _categories) {
          await _categoryListColl.doc(cat.id).delete();
        }

        // map fresh reords
        Map values_ = values as Map;
        _categories = values_.entries.map((e) {
          Map<Object?, Object?> map = e.value;
          Map<String, dynamic> temp = Map.castFrom(map);
          return Category.fromMap(temp);
        }).toList();

        // re-add fresh records to local
        await Future.delayed(const Duration(seconds: 1));
        for (var cat in _categories) {
          await _categoryListColl.doc(cat.id).set(cat.toMap());
        }
      }

      // get shopping list
      final res2 = await _dbRef.child(familyId).child(PrefsConsts.shoppingList).once();
      final values2 = res2.snapshot.value;
      if (values2 != null) {
        // clear local db
        for (var prod in _shoppingList) {
          await _shoppingListColl.doc(prod.id).delete();
        }

        // map fresh records
        Map values_ = values2 as Map;
        _shoppingList = values_.entries.map((e) {
          Map<Object?, Object?> map = e.value;
          Map<String, dynamic> temp = Map.castFrom(map);
          return Product.fromMap(temp);
        }).toList();

        // re-add fresh records to local
        await Future.delayed(const Duration(seconds: 1));
        for (var prod in _shoppingList) {
          await _shoppingListColl.doc(prod.id).set(prod.toMap());

          // check if there is a reminder
          if (prod.isDone == true) {
            if (ids.contains(prod.id) && prod.createdBy == user.address || prod.assignedTo!.contains(user.address)) {
              ids.remove(prod.id);
              String idString = ids.join(",");
              secStorage.write(key: PrefsConsts.notifiedIds, value: idString);
            }
          } else {
            if (prod.assignedTo!.contains(user.address) && prod.createdBy != user.address) {
              if (!ids.contains(prod.id)) {
                // save to storage
                ids.add(prod.id!);
                String idString = ids.join(",");
                secStorage.write(key: PrefsConsts.notifiedIds, value: idString);

                // set reminder
                if (context.mounted && prod.remindAt != null) {
                  try {
                    await AwesomeNotifications().createNotification(
                        content: NotificationContent(
                          id: prod.id.hashCode,
                          channelKey: NotifKeys.reminderChannel,
                          title: context.getString("details.reminder"),
                          body: context.getString("details.reminderBody", {"productName": prod.name}),
                          wakeUpScreen: true,
                          category: NotificationCategory.Reminder,
                          notificationLayout: NotificationLayout.Default,
                        ),
                        schedule:
                            NotificationCalendar.fromDate(date: DateTime.parse(prod.remindAt!), preciseAlarm: true));
                    if (context.mounted) {
                      snackBarHelper(context, message: context.getString("details.reminderSet"));
                    }
                  } on AwesomeNotificationsException catch (e) {
                    debugPrint(e.toString());
                  }
                }
              }
            }
          }
        }
      } else {
        _shoppingList = [];
        _shoppingListColl.delete();
      }

      // get family members list
      final res3 = await _dbRef.child(familyId).child(PrefsConsts.family).once();
      final dataRaw = res3.snapshot.value as Map;
      Map<String, dynamic> dataMap = Map.castFrom(dataRaw);

      Family family = Family(id: dataMap["id"], name: dataMap["name"], members: [], creator: dataMap["creator"]);
      List<User> members = [];

      for (var val in dataMap["members"]) {
        Map<String, dynamic> map = Map.castFrom(val);
        members.add(User.fromMap(map));
      }

      family.members = members;
      if (context.mounted) context.read<AuthProvider>().updateFam(context, family);

      _isGettingList = false;
      notifyListeners();
      return null;
    } on FirebaseException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      _isGettingList = false;
      notifyListeners();
      return _error;
    }
  }

  /// hide/show checked items in the list
  void filterList(bool filter) async {
    _isFiltered = filter;
    notifyListeners();
  }

  /// Search for a product to add to shopping list
  void search(BuildContext context, String query, String familyId) async {
    // get user
    final userString = await secStorage.read(key: PrefsConsts.user);
    User user = User.fromJson(userString!);

    if (query.trim().isEmpty) {
      clearSearchRes();
    }

    _searchRes = [];
    _isSearching = true;
    notifyListeners();

    if (query.trim().isNotEmpty) {
      for (var cat in _categories) {
        for (var prod in cat.products) {
          if (prod.toLowerCase().startsWith(query.toLowerCase().trim())) {
            String dateTime = DateTime.now().toUtc().toIso8601String();

            _searchRes.add(Product(
                id: generateId(),
                name: prod.titleCase,
                categoryName: cat.name,
                lastEdited: dateTime,
                createdBy: user.address));
          }
        }
      }

      if (_searchRes.isEmpty) {
        String dateTime = DateTime.now().toUtc().toIso8601String();
        // add item to search result under uncategorized category
        _searchRes.add(Product(
            id: generateId(),
            name: query.titleCase,
            categoryName: "uncategorized",
            lastEdited: dateTime,
            createdBy: user.address));
      }
    }

    _isSearching = false;
    _searchRes = [..._searchRes];
    notifyListeners();
  }

  /// add a product from search results to shopping list
  Future<void> addProductsFromSearch(
      BuildContext context, Product product, String familyId, List<String> notifRecipients) async {
    try {
      if (product.categoryName == "uncategorized") {
        // update uncategorized category
        int index = _categories.indexWhere((element) => element.id == "uncategorized");
        final cat = _categories[index];
        if (!cat.products.contains(product.name)) {
          cat.products = [...cat.products, product.name!];
          updateCategory(context, cat, familyId, false);
        }
      }

      _shoppingList.add(product);
      _shoppingList = [..._shoppingList];
      notifyListeners();

      // add to db
      await _dbRef.child(familyId).child(PrefsConsts.shoppingList).child(product.id!).set(product.toMap());

      // add to local
      await _shoppingListColl.doc(product.id).set(product.toMap());

      // notify family members except the creator
      NotificationProvider()
          .sendNotification(title: "New Product Added", message: product.name!, recipientIds: notifRecipients);
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      _shoppingList.remove(product);
      _shoppingList = [..._shoppingList];
      notifyListeners();
      if (context.mounted) snackBarHelper(context, message: _error, type: AnimatedSnackBarType.error);
    }
  }

  /// update a product data
  Future<void> updateProduct(BuildContext context, Product product, String familyId) async {
    // update time
    String dateTime = DateTime.now().toUtc().toIso8601String();
    product.lastEdited = dateTime;

    // find index
    int index = _shoppingList.indexWhere((element) => element.id == product.id);
    final oldProd = _shoppingList[index];

    try {
      // update in list
      _shoppingList[index] = product;
      _shoppingList = [..._shoppingList];
      notifyListeners();

      // update in db
      await _dbRef.child(familyId).child(PrefsConsts.shoppingList).child(product.id!).update(product.toMap());

      // update in local
      await _shoppingListColl.doc(product.id).set(product.toMap(), SetOptions(merge: true));
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      _shoppingList[index] = oldProd;
      _shoppingList = [..._shoppingList];
      notifyListeners();
      if (context.mounted) snackBarHelper(context, message: _error, type: AnimatedSnackBarType.error);
    }
  }

  /// delete a product from list
  Future<void> deleteProduct(BuildContext context,
      {required Product product,
      required String familyId,
      required List<String> recipientIds,
      required String username,
      required String familyName,
      bool showSnackBar = true}) async {
    // find index
    int index = _shoppingList.indexWhere((element) => element.id == product.id);
    final oldProd = _shoppingList[index];

    try {
      // delete in list
      _shoppingList.removeAt(index);
      _shoppingList = [..._shoppingList];
      notifyListeners();

      // update in db
      _dbRef.child(familyId).child(PrefsConsts.shoppingList).child(product.id!).remove();

      // update in local
      _shoppingListColl.doc(product.id).delete();

      if (context.mounted && showSnackBar) snackBarHelper(context, message: context.getString("home.deletedMessage"));

      // cancel reminder
      if (product.isDone == false) {
        if (product.remindAt != null) {
          if (context.mounted) {
            try {
              AwesomeNotifications().cancel(product.id.hashCode);
            } on AwesomeNotificationsException catch (e) {
              debugPrint(e.toString());
            }
          }
        }
      }

      // notify family members
      NotificationProvider().sendNotification(
          title: "Product Deleted",
          message: "$username deleted ${product.name} from the shopping list",
          recipientIds: recipientIds);
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      _shoppingList.insert(index, oldProd);
      _shoppingList = [..._shoppingList];
      notifyListeners();
      if (context.mounted) snackBarHelper(context, message: _error, type: AnimatedSnackBarType.error);
    }
  }

  /// create a new custom category
  Future<void> createNewCategory(BuildContext context, String name, String familyId) async {
    Category cat = Category(id: id(name), name: name, products: [], isCustomCategory: true);

    try {
      _categories.add(cat);
      _categories = [..._categories];
      notifyListeners();

      // to db
      await _dbRef.child(familyId).child(PrefsConsts.categoryList).child(cat.id).set(cat.toMap());
      // to local
      await _categoryListColl.doc(cat.id).set(cat.toMap());

      if (context.mounted) snackBarHelper(context, message: context.getString("manageCats.createSuccess"));
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      _categories.remove(cat);
      _categories = [..._categories];
      notifyListeners();
      if (context.mounted) snackBarHelper(context, message: _error, type: AnimatedSnackBarType.error);
    }
  }

  /// updates a custom category
  Future<void> updateCategory(BuildContext context, Category category, String familyId,
      [bool showSnackBar = true]) async {
    // find index
    int index = _categories.indexWhere((element) => element.id == category.id);
    final oldCat = _categories[index];

    try {
      // update in list
      _categories[index] = category;
      _categories = [..._categories];
      notifyListeners();

      // update in db
      await _dbRef.child(familyId).child(PrefsConsts.categoryList).child(category.id).update(category.toMap());

      // update in local
      await _categoryListColl.doc(category.id).set(category.toMap(), SetOptions(merge: true));
      if (context.mounted && showSnackBar) {
        snackBarHelper(context, message: context.getString("manageCats.updateSuccess"));
      }
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      _categories[index] = oldCat;
      _categories = [..._categories];
      notifyListeners();
      if (context.mounted && showSnackBar) snackBarHelper(context, message: _error, type: AnimatedSnackBarType.error);
    }
  }

  /// delete a custom category
  Future<void> deleteCategory(BuildContext context, Category category, String familyId) async {
    // find index
    int index = _categories.indexWhere((element) => element.id == category.id);
    final oldCat = _categories[index];

    try {
      // delete in list
      _categories.removeAt(index);
      _categories = [..._categories];
      notifyListeners();

      // update in db
      _dbRef.child(familyId).child(PrefsConsts.categoryList).child(category.id).remove();

      // update in local
      _categoryListColl.doc(category.id).delete();

      if (context.mounted) snackBarHelper(context, message: context.getString("manageCats.deleteSuccess"));
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      _categories.insert(index, oldCat);
      _categories = [..._categories];
      notifyListeners();
      if (context.mounted) snackBarHelper(context, message: _error, type: AnimatedSnackBarType.error);
    }
  }

  /// clear search result. Notify that search operations have ended and stop loading
  void clearSearchRes() {
    _searchRes = [];
    _isSearching = false;
    notifyListeners();
  }

  /// starts listenening for changes on family, shopping list and categories
  Future<void> streams(BuildContext context, String familyId) async {
    try {
      // categories
      _dbRef.child(familyId).child(PrefsConsts.categoryList).onValue.listen((event) async {
        final values = event.snapshot.value;

        if (values != null) {
          // clear local db
          for (var cat in _categories) {
            await _categoryListColl.doc(cat.id).delete();
          }

          // map fresh reords
          Map values_ = values as Map;
          _categories = values_.entries.map((e) {
            Map<Object?, Object?> map = e.value;
            Map<String, dynamic> temp = Map.castFrom(map);
            return Category.fromMap(temp);
          }).toList();

          // re-add fresh records to local
          await Future.delayed(const Duration(seconds: 1));
          for (var cat in _categories) {
            await _categoryListColl.doc(cat.id).set(cat.toMap());
          }
        }
        Future.delayed(const Duration(seconds: 1), () => notifyListeners());
      });

      // shoppingList
      _dbRef.child(familyId).child(PrefsConsts.shoppingList).onValue.listen((event) async {
        final values = event.snapshot.value;
        // get user
        final userString = await secStorage.read(key: PrefsConsts.user);
        User user = User.fromJson(userString!);

        // get notifiedIds
        final idsString = await secStorage.read(key: PrefsConsts.notifiedIds);
        List<String> ids = [];
        if (idsString != null) ids = idsString.split(",");

        if (values != null) {
          // clear local db
          for (var prod in _shoppingList) {
            await _categoryListColl.doc(prod.id).delete();
          }

          // map fresh reords
          Map values_ = values as Map;
          _shoppingList = values_.entries.map((e) {
            Map<Object?, Object?> map = e.value;
            Map<String, dynamic> temp = Map.castFrom(map);
            return Product.fromMap(temp);
          }).toList();

          // re-add fresh records to local
          await Future.delayed(const Duration(seconds: 1));
          for (var prod in _shoppingList) {
            await _shoppingListColl.doc(prod.id).set(prod.toMap());

            // check if there is a reminder
            if (prod.isDone == true) {
              if (ids.contains(prod.id) && prod.createdBy == user.address || prod.assignedTo!.contains(user.address)) {
                ids.remove(prod.id);
                String idString = ids.join(",");
                secStorage.write(key: PrefsConsts.notifiedIds, value: idString);
              }
            } else {
              if (prod.assignedTo!.contains(user.address) && prod.createdBy != user.address) {
                if (!ids.contains(prod.id)) {
                  // save to storage
                  ids.add(prod.id!);
                  String idString = ids.join(",");
                  secStorage.write(key: PrefsConsts.notifiedIds, value: idString);

                  // notify

                  // schedule reminder
                  // set reminder
                  if (context.mounted && prod.remindAt != null) {
                    try {
                      await AwesomeNotifications().createNotification(
                          content: NotificationContent(
                            id: prod.id.hashCode,
                            channelKey: NotifKeys.reminderChannel,
                            title: context.getString("details.reminder"),
                            body: context.getString("details.reminderBody", {"productName": prod.name}),
                            wakeUpScreen: true,
                            category: NotificationCategory.Reminder,
                            notificationLayout: NotificationLayout.Default,
                          ),
                          schedule:
                              NotificationCalendar.fromDate(date: DateTime.parse(prod.remindAt!), preciseAlarm: true));
                      if (context.mounted) {
                        snackBarHelper(context, message: context.getString("details.reminderSet"));
                      }
                    } on AwesomeNotificationsException catch (e) {
                      debugPrint(e.toString());
                    }
                  }
                }
              }
            }
          }
        } else {
          _shoppingList = [];
          await _shoppingListColl.delete();
        }
        Future.delayed(const Duration(seconds: 1), () => notifyListeners());
      });

      // family
      _dbRef.child(familyId).child(PrefsConsts.family).onValue.listen((event) async {
        final dataRaw = event.snapshot.value as Map;
        Map<String, dynamic> dataMap = Map.castFrom(dataRaw);

        Family family = Family(id: dataMap["id"], name: dataMap["name"], members: [], creator: dataMap["creator"]);
        List<User> members = [];

        for (var val in dataMap["members"]) {
          Map<String, dynamic> map = Map.castFrom(val);
          members.add(User.fromMap(map));
        }

        family.members = members;
        if (context.mounted) context.read<AuthProvider>().updateFam(context, family);
        Future.delayed(const Duration(seconds: 1), () => notifyListeners());
      });
    } on FirebaseException catch (e) {
      _error = e.message ?? "Unknown error";
      debugPrint(_error);
    }
  }

  /// for adding a new member to fam, butalso work nomally as an update function
  Future<String?> updateFam(Family family) async {
    try {
      await _dbRef.child(family.id).child(PrefsConsts.family).update(family.toMap());
      return null;
    } on FirebaseException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      return _error;
    }
  }

  /// clears local database and provider data when user logs out
  Future<void> onLogout() async {
    await _shoppingListColl.delete();
    await _categoryListColl.delete();
    _searchRes = [];
    _shoppingList = [];
    _isFiltered = false;
    _categories = [];
    notifyListeners();
  }
}

/// Removes special characters from category name and returns modified string as category id
String id(String name) {
  return name.toLowerCase().replaceAll(" ", "").replaceAll("&", "").replaceAll("-", "");
}
