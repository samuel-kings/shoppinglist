import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Instance of Firebase storage declared for global access
var storage = FirebaseStorage.instance;

/// Uploads an image to Firebase storage in the path "attachedImages/[productId]"
/// Returns the url of the uploaded image if operation successful and an error instead, if not.
Future<({String? url, String? error})> uploadImageToFirebase(File imageFile, String productId) async {
  try {
    // compress file
    var bytes = await FlutterImageCompress.compressWithFile(imageFile.absolute.path, quality: 80);

    TaskSnapshot taskSnapshot = await storage.ref('attachedImages/$productId').putData(bytes!);
    final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return (url: downloadUrl, error: null);
  } catch (e) {
    debugPrint(e.toString());
    return (url: null, error: e.toString());
  }
}

/// Deletes an image from Firebase storage bucket located at "attachedImages/[productId]"
/// Returns the null if operation successful and an error instead, if not.
Future<String?> deleteFileFromFirebase(String productId) async {
  try {
    await storage.ref('attachedImages/$productId').delete();
    return null;
  } catch (e) {
    debugPrint("error deleting db from cloud: $e");
    return e.toString();
  }
}
