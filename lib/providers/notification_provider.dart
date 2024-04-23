import 'package:flutter/material.dart';
import 'package:one_signal_api/api.dart' as os_api;

class NotificationProvider extends ChangeNotifier {
  String _error = "";

  String get error => _error;

  /// send a notification to a user
  Future<bool> sendNotification(
      {required String title,
      required String message,
      required List<String> recipientIds,
      Map<String, dynamic>? data}) async {
    final apiInstance = os_api.DefaultApi();
    const appId = "4344420b-6f4f-41af-9763-ec2c852e3c5b";
    const key = "YTlmOTM0MDctYzA1MC00MWY1LWJlOTMtZTAyYjY3N2Y4NTRj";

    try {
      // authentictae api
      apiInstance.apiClient.addDefaultHeader("Authorization", "Basic $key");

      final notification = os_api.Notification(
          appId: appId,
          includeExternalUserIds: recipientIds,
          isAndroid: true,
          channelForExternalUserIds: 'push',
          isIos: true,
          contents: os_api.StringMap(
            en: message,
          ),
          headings: os_api.StringMap(en: title),
          data: data);

      // send notification
      await apiInstance.createNotification(notification);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint(e.toString());
      return false;
    }
  }
}
