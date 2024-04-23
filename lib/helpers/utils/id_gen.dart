import 'package:random_string/random_string.dart';

/// Generate a unique 40 alphanumeric characters used as user ID, family ID and item ID (products withing the shopping list)
String generateId() {
  return randomAlphaNumeric(40);
}
