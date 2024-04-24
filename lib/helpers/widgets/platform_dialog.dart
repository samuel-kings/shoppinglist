import 'package:flutter/material.dart';
import 'package:shoppinglist/helpers/widgets/sized_boxes.dart';

/// a custom adaptive dialog
///
/// PS: This can now be replaced with new Flutter adaptive dialog introduced in 3.11
platformDialog(
    {required BuildContext context,
    required String title,
    required String message,
    required Function() onContinue,
    required String cancelText,
    required String continueText,
    bool showCancel = true,
    List<Widget>? others}) {
  showAdaptiveDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog.adaptive(
          title: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text(message, style: Theme.of(ctx).textTheme.bodyMedium), if (others != null) ...others],
          ),
          titlePadding: const EdgeInsets.all(16),
          contentPadding: const EdgeInsets.all(16),
          actionsPadding: EdgeInsets.all(showCancel ? 16 : 5),
          actionsAlignment: !showCancel ? MainAxisAlignment.start : MainAxisAlignment.center,
          actions: [
            if (showCancel)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(cancelText, style: Theme.of(ctx).textTheme.titleSmall),
              ),
            if (!showCancel) w20,
            TextButton(
              onPressed: () {
                onContinue();
                Navigator.of(ctx).pop();
              },
              child:
                  Text(continueText, style: Theme.of(ctx).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold)),
            )
          ],
        );
      });
}
