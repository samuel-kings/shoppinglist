import 'package:flutter/material.dart';
import 'loading_animation.dart';

/// A custom elevated button that can also show a loading indicator where necessary
Widget customButton(
  BuildContext context, {
  required IconData icon,
  required String text,
  bool isLoading = false,
  required VoidCallback onPressed,
}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          fixedSize: const Size(double.infinity, 50)),
      child: isLoading ? loadingAnimation(context) : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon), const SizedBox(width: 10), Text(text, style: Theme.of(context).textTheme.labelLarge)],
      ),
    );
}