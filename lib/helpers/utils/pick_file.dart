import 'dart:io';
import 'package:file_picker/file_picker.dart';

// Picks a file from user's device and return null if no file was picked or operation cancelled
Future<File?> pickFile() async {
  final res = await FilePicker.platform.pickFiles(type: FileType.image);

  if (res != null) {
    return File(res.files.single.path!);
  } else {
    return null;
  }
}
