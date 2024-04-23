import 'dart:convert';
import 'dart:io';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shoppinglist/consts/prefs_consts.dart';
import 'package:shoppinglist/helpers/utils/id_gen.dart';
import 'package:shoppinglist/helpers/utils/sec_storage.dart';
import 'package:shoppinglist/helpers/widgets/snackbar_helper.dart';
import 'package:shoppinglist/main.dart';
import 'package:shoppinglist/models/family.dart';
import 'package:shoppinglist/providers/notification_provider.dart';
import 'package:shoppinglist/providers/shopping_list_provider.dart';
import 'package:shoppinglist/screens/auth_flow_screen.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  String _error = "";
  User? _user;
  Family? _family;
  final _dbRef = FirebaseDatabase.instance.ref();

  /// Error message of last executed method
  String get error => _error;

  /// Logged-in user object
  User? get user => _user;

  /// Logged-in user's amily object
  Family? get family => _family;

  /// Gets the current loggedIn user data from local storage. Returns null
  /// if no user session is found.
  Future<User?> getUser() async {
    final userString = await secStorage.read(key: PrefsConsts.user);

    if (userString != null) {
      _user = User.fromJson(userString);

      // get family
      final famString = await secStorage.read(key: PrefsConsts.family);
      _family = Family.fromJson(famString!);
    } else {
      _user = null;
      _family = null;
    }

    notifyListeners();
    return _user;
  }

  /// Checks if user has been onboarded
  Future<bool> isOnboarded() async {
    final isOnboarded = await secStorage.read(key: PrefsConsts.language);
    return isOnboarded != null;
  }

  /// Save user preferred locale
  Future<void> saveLanguage(String language) async {
    await secStorage.write(key: PrefsConsts.language, value: language);
    countryCode = language;
  }

  /// Get user prefereed locale. Returns "en" by default
  Future<String> getSavedLang() async {
    return countryCode = (await secStorage.read(key: PrefsConsts.language)) ?? "en";
  }

  /// Creates a new user account, family and adds default categories to family data
  Future<bool> createFamily(User user, Family family) async {
    try {
      // create data in firebase
      final res = await ShoppingListsProvider().createListsOnAcctCreation(family);

      // save data to local storage
      await secStorage.write(key: PrefsConsts.user, value: jsonEncode(user.toMap()));
      await secStorage.write(key: PrefsConsts.family, value: jsonEncode(family.toMap()));

      if (res != null) {
        _error = res;
        return false;
      }

      await getUser();
      return true;
    } on HttpException catch (e) {
      _error = e.message;
      debugPrint(_error);
      return false;
    }
  }

  /// Creates a new user and adds to an existing family
  Future<bool> joinFamily(BuildContext context, String userName, String familyId) async {
    final shoppingProvider = ShoppingListsProvider();

    try {
      // check if family exists
      final familyDoc = await _dbRef.child(familyId).get();
      if (familyDoc.exists) {
        // check if user exists
        final famMap = familyDoc.child("family").value as Map;

        _family = Family.fromMap(famMap);

        bool isExist = _family!.members.any((member) => member.name == userName);

        if (isExist) {
          // log user in
          _user = _family!.members.firstWhere((member) => member.name == userName);
          await secStorage.write(key: PrefsConsts.user, value: jsonEncode(_user?.toMap()));
          await secStorage.write(key: PrefsConsts.family, value: jsonEncode(_family?.toMap()));

          await getUser();

          return true;
        } else {
          // add member to family
          String uId = generateId();
          _user = User(
              address: uId, familyId: _family!.id, name: userName, createdAt: DateTime.now().toUtc().toIso8601String());

          _family?.members.add(_user!);

          final isUpdated = await shoppingProvider.updateFam(_family!);

          // return error if error occured
          if (isUpdated != null) {
            _error = shoppingProvider.error;
            return false;
          }

          // save data to local storage
          await secStorage.write(key: PrefsConsts.user, value: jsonEncode(_user!.toMap()));
          await secStorage.write(key: PrefsConsts.family, value: jsonEncode(_family!.toMap()));

          // notifiy the family
          NotificationProvider().sendNotification(
              title: "${_family?.name} Family Update",
              message: "$userName has joined the family",
              recipientIds: _family!.members.map((e) => e.address).toList());

          await getUser();

          return true;
        }
      } else {
        _error = "Family does not exist";
        return false;
      }
    } on FirebaseException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      return false;
    }
  }

  /// Removes a member from a family.
  /// Not in use at the moment
  Future<bool> removeMember(String userId) async {
    try {
      _family!.members.removeWhere((user) => user.address == userId);

      // update family data in the database
      final res = await ShoppingListsProvider().updateFam(_family!);

      if (res != null) {
        _error = res;
        return false;
      }

      // update local storage
      await secStorage.write(key: PrefsConsts.family, value: jsonEncode(_family!.toMap()));

      // notify the deleted user
      NotificationProvider().sendNotification(
          title: "${_family?.name} Family Update",
          message: "You have been removed from the family",
          recipientIds: [userId]);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      return false;
    }
  }

  /// Logs user out and deletes all cached and local storage data
  Future<void> logout() async {
    await secStorage.delete(key: PrefsConsts.family);
    await secStorage.delete(key: PrefsConsts.user);
    await secStorage.delete(key: PrefsConsts.isNotifsGranted);
    _user = null;
    _family = null;
    await ShoppingListsProvider().onLogout();
    notifyListeners();
    await getUser();
    OneSignal.shared.removeExternalUserId();
  }

  /// Update faamily data in local storage and provider
  void updateFam(BuildContext context, Family family) {
    // check if user is still part of the family
    bool isExist = family.members.any((member) => member.address == _user?.address);

    if (isExist) {
      _family = family;
      secStorage.write(key: PrefsConsts.family, value: jsonEncode(family.toMap()));
      notifyListeners();
    } else {
      logout();

      snackBarHelper(context, message: "You have been removed from the family", type: AnimatedSnackBarType.error);

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AuthFlowScreen()));
    }
  }
}
