import 'package:flutter_secure_storage/flutter_secure_storage.dart';

AndroidOptions _getAndroidOptions() => const AndroidOptions(
      encryptedSharedPreferences: true,
    );
FlutterSecureStorage  _secStorage = FlutterSecureStorage(aOptions: _getAndroidOptions());
/// Initialized Flutter Secure Storage object. A secured version of Shared Preferences
FlutterSecureStorage get secStorage => _secStorage;