import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// custom loading/progress indicator
Widget loadingAnimation(BuildContext context) {
  return Center(child: LoadingAnimationWidget.threeArchedCircle(color: Theme.of(context).colorScheme.primary, size: 30));
}