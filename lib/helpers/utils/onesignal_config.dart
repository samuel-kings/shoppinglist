import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shoppinglist/models/family.dart';
import 'package:shoppinglist/models/product.dart';
import 'package:shoppinglist/providers/shopping_list_provider.dart';
import 'package:provider/provider.dart';
import 'package:shoppinglist/screens/details_screen.dart.dart';

/// Onesignal push notifications configuration
/// PS: Initialization already happened in the main() function
Future<void> onesignalConfig(BuildContext? context, String? userId) async {
  OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event) {
    event.complete(event.notification);
  });
  OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {});
  OneSignal.shared.setSubscriptionObserver((OSSubscriptionStateChanges changes) {});

  // handle notification opened
  OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) async {
    final payload = result.notification.additionalData;
    if (payload != null && context != null) {
      // get data from payload
      Product product = Product.fromJson(payload["product"]);
      Family family = Family.fromJson(payload["family"]);

      // fetch updated data
      final provider = context.read<ShoppingListsProvider>();
      await provider.getLists(context, family.id).then((value) {
        provider.streams(context, family.id).then((value) {
          // assign
          product = provider.shoppingList.where((element) => element.id == product.id).first;

          if (context.mounted) {
            Future.delayed(
                const Duration(seconds: 1),
                () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => DetailsScreen(product: product, family: family))));
          }
        });
      });
    }
  });

  if (userId != null) OneSignal.shared.setExternalUserId(userId);
}
