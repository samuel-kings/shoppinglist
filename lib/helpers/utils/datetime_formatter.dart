import 'package:intl/intl.dart';

/// Receives a DateTime object and return date and time in a string with this format "Sep 4, 2023 3:30 PM"
String getDateTime(DateTime dateTime) {
  final dateFormat = DateFormat.yMMMd();
  final timeFormat = DateFormat.jm();

  final formattedDate = dateFormat.format(dateTime);
  final formattedTime = timeFormat.format(dateTime);

  return "$formattedDate $formattedTime";
}
