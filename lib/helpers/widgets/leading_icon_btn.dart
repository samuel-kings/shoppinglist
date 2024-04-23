import 'package:flutter/material.dart';

/// A re-usable ios-styled back button
Widget leadingIcnBtn(BuildContext context) {
  return IconButton(onPressed: () =>Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_ios_new));
}
