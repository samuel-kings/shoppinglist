import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shoppinglist/helpers/widgets/loading_animation.dart';

/// A re-usable widget for caching network image
Widget cnImage(String url, Size size) {
  return CachedNetworkImage(
    imageUrl: url,
    imageBuilder: (context, imageProvider) => Container(
      height: size.height,
      width: size.width,
      decoration: BoxDecoration(
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    ),
    placeholder: (context, url) => Padding(
      padding: const EdgeInsets.all(16.0),
      child: loadingAnimation(context),
    ),
    errorWidget: (context, url, error) => const Padding(
      padding: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: Icon(Icons.error)),
      ),
    ),
  );
}
