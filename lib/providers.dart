import 'package:shoppinglist/providers/auth_provider.dart';
import 'package:shoppinglist/providers/shopping_list_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> providers = [
  ChangeNotifierProvider(create: (context) => AuthProvider()),
  ChangeNotifierProvider(create: (context) => ShoppingListsProvider()),
];
