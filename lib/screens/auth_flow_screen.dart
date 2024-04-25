import 'dart:async';
import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shoppinglist/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shoppinglist/screens/home_screen.dart';
import 'package:shoppinglist/screens/onboarding/create_account_name_screen.dart';
import 'package:shoppinglist/screens/select_lang_screen.dart';

/// This screen check the user auth status and redirects to the appropriate screen
class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({Key? key}) : super(key: key);

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> with AfterLayoutMixin {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }

  /// check the user auth status and redirects to the appropriate screen
  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    AuthProvider provider = context.read<AuthProvider>();

    // check if it's first app launch
    bool isOnboarded = await provider.isOnboarded();

    if (!context.mounted) return;

    // if user hasn't been onboarded, redirect to select default language, then onbaord
    if (!isOnboarded) {
      FlutterNativeSplash.remove();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const SelectLangScreen()));
      return;
    }

    // if onboarded, check if user is logged in
    final user = await provider.getUser();
    FlutterNativeSplash.remove();

    if (!context.mounted) return;

    if (user == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const CreateAccountNameScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
    }
  }
}
