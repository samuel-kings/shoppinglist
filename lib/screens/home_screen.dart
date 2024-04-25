import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:collection/collection.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:ez_localization/ez_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoppinglist/helpers/utils/onesignal_config.dart';
import 'package:shoppinglist/helpers/widgets/loading_animation.dart';
import 'package:shoppinglist/helpers/widgets/platform_dialog.dart';
import 'package:shoppinglist/helpers/widgets/sized_boxes.dart';
import 'package:shoppinglist/helpers/widgets/snackbar_helper.dart';
import 'package:shoppinglist/models/product.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:shoppinglist/providers/notification_provider.dart';
import 'package:shoppinglist/screens/details_screen.dart.dart';
import 'package:shoppinglist/screens/profile_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/family.dart';
import '../providers/auth_provider.dart';
import '../providers/shopping_list_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  ShoppingListsProvider _listsProvider = ShoppingListsProvider();
  final List<String> _selection = [];
  AuthProvider _authProvider = AuthProvider();
  late Family _family;
  final _searchController = TextEditingController();
  bool _showCategories = true;
  bool _sortPriority = false;
  bool _sortByLastEdited = false;

  bool _hasShownWarning = false;

  final List<Product> _demoList = List.generate(
      10,
      (index) => Product(
          id: "id$index",
          name: "Loaing... Product $index",
          createdBy: "1234567890",
          isDone: false,
          categoryName: "Category $index",
          assignedTo: [],
          remindAt: "",
          addedPhotoUrl: "",
          note: "",
          lastEdited: "",
          priority: 1,
          estimatedPrice: "0",
          actualPrice: "0"));

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _listsProvider = context.read<ShoppingListsProvider>();
    _family = _authProvider.family!;
    // get category and shopping lists, then start streaming
    _listsProvider.getLists(context, _family.id);
    _listsProvider.streams(context, _family.id);

    onesignalConfig(context, _authProvider.user!.address);

    // // check notifs permission
    // AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    //   if (!isAllowed) {
    //     platformDialog(
    //         context: context,
    //         title: context.getString("general.enableNotifsDialogTitle"),
    //         message: context.getString("general.enableNotifsDialogBody"),
    //         onContinue: () async {
    //           bool isGranted = await AwesomeNotifications().requestPermissionToSendNotifications();

    //            if (!context.mounted) return;
    //           if (isGranted) {
    //             snackBarHelper(context, message: context.getString("general.enabled"));
    //           } else {
    //             snackBarHelper(context,
    //                 message: context.getString("general.disabled"), type: AnimatedSnackBarType.warning);
    //           }
    //         },
    //         onCancel: () => snackBarHelper(context,
    //             message: context.getString("general.disabled"), type: AnimatedSnackBarType.warning),
    //         cancelText: context.getString("general.cancel"),
    //         continueText: context.getString("general.enable"));
    //   }
    // });
  }

  String _getPriority(int priority) {
    switch (priority) {
      case 1:
        return "Low";
      case 2:
        return "Medium";
      case 3:
        return "High";
      default:
        return "Low";
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Indicates if checked/done items are the shopping list are hidden or shown
    bool isFiltered = context.select<ShoppingListsProvider, bool>((provider) => provider.isFiltered);
    List<Product> list = context.select<ShoppingListsProvider, List<Product>>((provider) => provider.shoppingList);
    final menuItems = [
      // filter ==> hide/show done items
      PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(isFiltered ? Icons.remove_red_eye_outlined : CommunityMaterialIcons.eye_off),
              w8,
              Text(context.getString(isFiltered ? "home.show" : "home.hide"),
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          )),
      // hide or show categories
      PopupMenuItem(
          value: 4,
          child: Row(
            children: [
              const Icon(Icons.category_outlined),
              w8,
              Text(context.getString(_showCategories ? "home.hideCat" : "home.showCat"),
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          )),
      // markSelectedComplete
      PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              const Icon(CommunityMaterialIcons.checkbox_multiple_marked_circle),
              w8,
              Expanded(
                child:
                    Text(context.getString("home.markSelectedComplete"), style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          )),
      // markSelectedUnomplete
      PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              const Icon(CommunityMaterialIcons.checkbox_multiple_marked_circle_outline),
              w8,
              Expanded(
                child: Text(context.getString("home.markSelectedUncomplete"),
                    style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          )),
      // deleteSelected
      PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              w8,
              Text(context.getString("home.deleteSelected"),
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red)),
            ],
          )),
      // filter by priority
      PopupMenuItem(
          value: 5,
          child: Row(
            children: [
              const Icon(CommunityMaterialIcons.sort),
              w8,
              Expanded(
                child: Text(context.getString("home.sortByPriority"), style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          )),
      // sort by last edited
      PopupMenuItem(
          value: 6,
          child: Row(
            children: [
              const Icon(CommunityMaterialIcons.timelapse),
              w8,
              Expanded(
                child: Text(context.getString("home.sortByLastEdited"), style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          )),
    ];

    return Selector<ShoppingListsProvider, ({bool isLoading, bool isFiltered, List<Product> shoppingList})>(
        selector: (_, provider) =>
            (isLoading: provider.isGettingList, isFiltered: provider.isFiltered, shoppingList: provider.shoppingList),
        builder: (context, record, child) {
          final isLoading = record.isLoading;
          var shoppingListAll = isFiltered
              ? record.shoppingList.where((element) => element.isDone != true).toList()
              : record.shoppingList;

          List<Product> done, unDone;
          done = shoppingListAll.where((element) => element.isDone == true).toList();
          unDone = shoppingListAll.where((element) => element.isDone != true).toList();

          if (_sortByLastEdited) {
            done.sortBy((element) => DateTime.parse(element.lastEdited));
            unDone.sortBy((element) => DateTime.parse(element.lastEdited));
          } else {
            done.sort((b, a) => b.priority!.compareTo(a.priority!));
            unDone.sort((b, a) => b.priority!.compareTo(a.priority!));
          }

          List<Product> shoppingList = [...unDone.reversed.toList(), ...done.reversed.toList()];

          // notify user to add estimated price if it's not added
          if (!_hasShownWarning && shoppingList.isNotEmpty) {
            for (var item in shoppingList) {
              if (item.estimatedPrice == null || item.estimatedPrice!.isEmpty || item.estimatedPrice == "0") {
                Future.delayed(const Duration(seconds: 2), () {
                  snackBarHelper(context,
                      message: "One or more products do not have estimated price set. Please add now",
                      type: AnimatedSnackBarType.warning);
                });

                _hasShownWarning = true;
                break;
              }
            }
          }

          // add reminders for products marked as completed without actual prices
          for (var item in shoppingList) {
            if (item.isDone == true && (item.actualPrice == null || item.actualPrice!.isEmpty || item.actualPrice == "0")) {
              Future.delayed(const Duration(seconds: 2), () {
                snackBarHelper(context,
                    message: "One or more products marked as done do not have actual price set. Please add now",
                    type: AnimatedSnackBarType.warning);
              });
              break;
            }
          }

          return Scaffold(
            appBar: AppBar(
                title: Text(context.getString("home.title"), style: Theme.of(context).textTheme.titleMedium),
                automaticallyImplyLeading: false,
                centerTitle: true,
                actions: [
                  // settings
                  Skeletonizer(
                    enabled: isLoading,
                    child: IconButton(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen())),
                        icon: const Icon(Icons.settings_outlined)),
                  ),
                  w8,
                  // more
                  Visibility(
                    visible: list.isNotEmpty && !isLoading,
                    child: InkWell(
                        onTapDown: (details) async {
                          final RenderBox referenceBox = context.findRenderObject() as RenderBox;
                          final Offset tapPosition = referenceBox.globalToLocal(details.globalPosition);

                          final RenderObject? overlay = Overlay.of(context).context.findRenderObject();

                          final positionRelativeToButton = RelativeRect.fromRect(
                              Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 30, 30),
                              Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height));

                          bool isAnyDone = false;
                          for (var item in list) {
                            if (item.isDone == true) {
                              isAnyDone = true;
                              break;
                            }
                          }

                          List<PopupMenuEntry<int>> items = [];

                          if (list.isNotEmpty && !isAnyDone && _selection.isEmpty) {
                            items.add(menuItems[1]);
                          } else if (list.isNotEmpty && isAnyDone && _selection.isEmpty) {
                            items.add(menuItems[0]);
                            items.add(menuItems[1]);
                          } else if (list.isNotEmpty && isAnyDone && _selection.isNotEmpty) {
                            items = menuItems;
                          } else {
                            items = menuItems;
                            items.removeAt(0);
                          }

                          items.add(menuItems[5]);
                          items.add(menuItems[6]);

                          final selected =
                              await showMenu(context: context, position: positionRelativeToButton, items: items);

                          if (context.mounted) {
                            List<String> recipientIds = _family.members.map((e) => e.address).toList();
                            recipientIds.remove(_authProvider.user!.address);
                            switch (selected) {
                              case 0:
                                // filter
                                if (!isFiltered) {
                                  _listsProvider.filterList(true);
                                } else {
                                  _listsProvider.filterList(false);
                                }
                                break;
                              case 1:
                                // check selected
                                for (var id in _selection) {
                                  final product = list.where((element) => element.id == id).first;
                                  product.isDone = true;
                                  await _listsProvider.updateProduct(context, product, _family.id);
                                  NotificationProvider().sendNotification(
                                      title: "Product marked as done",
                                      message:
                                          "${product.name} | ${product.categoryName} by ${_authProvider.user?.name}",
                                      recipientIds: recipientIds);
                                }
                                _selection.clear();
                                setState(() {});
                                if (!context.mounted) return;
                                break;
                              case 2:
                                // uncheck selected
                                for (var id in _selection) {
                                  final product = list.where((element) => element.id == id).first;
                                  product.isDone = false;
                                  await _listsProvider.updateProduct(context, product, _family.id);

                                  NotificationProvider().sendNotification(
                                      title: "Product marked as undone",
                                      message:
                                          "${product.name} | ${product.categoryName} by ${_authProvider.user?.name}",
                                      recipientIds: recipientIds);
                                }
                                _selection.clear();
                                setState(() {});
                                if (!context.mounted) return;
                                break;
                              case 3:
                                // delete selected
                                platformDialog(
                                    context: context,
                                    title: context.getString("home.delete"),
                                    message: context.getString("home.sureToDeleteSelected"),
                                    onContinue: () async {
                                      for (var id in _selection) {
                                        final product = list.where((element) => element.id == id).first;
                                        product.isDone = false;
                                        List<String> recipientIds = _family.members.map((e) => e.address).toList();
                                        recipientIds.remove(_authProvider.user!.address);

                                        await _listsProvider.deleteProduct(context,
                                            product: product,
                                            familyId: _family.id,
                                            recipientIds: recipientIds,
                                            username: _authProvider.user!.name,
                                            familyName: _family.name,
                                            showSnackBar: id == _selection.last);
                                      }
                                      _selection.clear();
                                      setState(() {});
                                    },
                                    cancelText: context.getString("general.cancel"),
                                    continueText: context.getString("general.continue"));

                                break;
                              case 4:
                                setState(() {
                                  _showCategories = !_showCategories;
                                  _sortPriority = false;
                                  _sortByLastEdited = false;
                                });
                                break;
                              case 5:
                                setState(() {
                                  _sortPriority = !_sortPriority;
                                  _showCategories = false;
                                  _sortByLastEdited = false;
                                });
                                break;
                              case 6:
                                setState(() {
                                  _sortByLastEdited = !_sortByLastEdited;
                                  _sortPriority = false;
                                });
                                break;
                              default:
                            }
                          }
                        },
                        child: const Icon(Icons.more_vert)),
                  ),
                  w8
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50.0),
                  child: Skeletonizer(
                    enabled: isLoading,
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SearchBar(
                          controller: _searchController,
                          leading: const Icon(Icons.search),
                          shadowColor: const MaterialStatePropertyAll(Colors.transparent),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0.0),
                          )),
                          padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
                          hintText: context.getString("home.searchHint"),
                          hintStyle: MaterialStatePropertyAll(GoogleFonts.montserrat(
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          )),
                          textStyle: MaterialStatePropertyAll(GoogleFonts.montserrat(
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          )),
                          trailing: [
                            // if (_searchController.text.isNotEmpty)
                            IconButton(
                                onPressed: () {
                                  _listsProvider.clearSearchRes();
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear_all))
                          ],
                          onChanged: (value) async {
                            _listsProvider.search(context, value, _family.id);
                          },
                        )),
                  ),
                )),
            floatingActionButton: Visibility(
              visible: !isLoading && shoppingList.isNotEmpty,
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      // isScrollControlled: true,
                      builder: (context) {
                        int estimatedPrice = 0;
                        int actualPrice = 0;
                        int difference = 0;

                        for (var item in shoppingList) {
                          if (item.estimatedPrice != null &&
                              item.estimatedPrice!.isNotEmpty &&
                              item.estimatedPrice != "0") {
                            int price = int.parse(item.estimatedPrice!.replaceAll(",", "").replaceAll("₦", ""));
                            estimatedPrice += price;
                          }
                          if (item.actualPrice != null && item.actualPrice!.isNotEmpty && item.actualPrice != "0") {
                            int price = int.parse(item.actualPrice!.replaceAll(",", "").replaceAll("₦", ""));
                            actualPrice += price;
                          }
                        }

                        difference = estimatedPrice - actualPrice;

                        String estimatedPriceStr =
                            CurrencyTextInputFormatter.currency(symbol: "₦", locale: "en_NG", decimalDigits: 0)
                                .formatString(estimatedPrice.toString());
                        String actualPriceStr =
                            CurrencyTextInputFormatter.currency(symbol: "₦", locale: "en_NG", decimalDigits: 0)
                                .formatString(actualPrice.toString());
                        String differenceStr =
                            CurrencyTextInputFormatter.currency(symbol: "₦", locale: "en_NG", decimalDigits: 0)
                                .formatString(difference.toString());
                        Color color = difference < 0 ? Colors.red : Colors.green;

                        List<({String title, String value})> info = [
                          (title: "Total Estimated Cost", value: estimatedPriceStr),
                          (title: "Amount Spent", value: actualPriceStr),
                          (title: "Difference", value: differenceStr)
                        ];

                        return Column(
                          children: [
                            // summary
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Summary", style: Theme.of(context).textTheme.titleMedium),
                                  IconButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      icon: const Icon(Icons.close))
                                ],
                              ),
                            ),
                            const Divider(),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                itemCount: info.length,
                                itemBuilder: (BuildContext context, int index) {
                                  bool isDiff = info[index].title == "Difference";

                                  return ListTile(
                                    title: Text(info[index].title, style: Theme.of(context).textTheme.titleMedium),
                                    trailing: Text(info[index].value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(color: isDiff ? color : null)),
                                  );
                                },
                              ),
                            )
                          ],
                        );
                      });
                },
                child: const Icon(CupertinoIcons.info, size: 25),
              ),
            ),
            body: DoubleBackToCloseApp(
              snackBar: SnackBar(
                content: Text(context.getString("home.exit"),
                    style:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.surface)),
              ),
              child: Stack(
                children: [
                  // products list
                  if (isLoading)
                    _loadingShimmer()
                  else
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // sort by priority
                          children: _sortPriority
                              ? groupBy(shoppingList, (Product product) => product.priority).entries.map((group) {
                                  return ExpansionTile(
                                    collapsedBackgroundColor:
                                        Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                                    backgroundColor: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                                    childrenPadding: EdgeInsets.zero,
                                    initiallyExpanded: true,
                                    maintainState: true,
                                    shape: const RoundedRectangleBorder(),
                                    title: Row(
                                      children: [
                                        Container(
                                          height: 10,
                                          width: 10,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _getPriorityColor(group.key!.toInt()),
                                              border: Border.all(
                                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                                  width: 0.5)),
                                        ),
                                        w8,
                                        Text(_getPriority(group.key!.toInt()),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(color: Theme.of(context).colorScheme.primary)),
                                      ],
                                    ),
                                    children: group.value.map((prod) {
                                      bool isSelected = _selection.contains(prod.id!);
                                      int index = group.value.indexOf(prod);
                                      bool isLastItem = true;
                                      if (index == (group.value.length - 1)) {
                                        isLastItem = true;
                                      }

                                      return _buildItem(prod, isSelected, isLastItem);
                                    }).toList(),
                                  );
                                }).toList()
                              // sort by category
                              : _showCategories
                                  ? groupBy(shoppingList, (Product product) => product.categoryName ?? "")
                                      .entries
                                      .map((group) {
                                      return ExpansionTile(
                                        collapsedBackgroundColor:
                                            Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                                        backgroundColor: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                                        childrenPadding: EdgeInsets.zero,
                                        initiallyExpanded: true,
                                        maintainState: true,
                                        shape: const RoundedRectangleBorder(),
                                        title: Container(
                                          alignment: Alignment.centerLeft,
                                          child: Text(group.key.toUpperCase(),
                                              style: Theme.of(context).textTheme.bodySmall),
                                        ),
                                        children: group.value.map((prod) {
                                          bool isSelected = _selection.contains(prod.id!);
                                          int index = group.value.indexOf(prod);
                                          bool isLastItem = true;
                                          if (index == (group.value.length - 1)) {
                                            isLastItem = true;
                                          }

                                          return _buildItem(prod, isSelected, isLastItem);
                                        }).toList(),
                                      );
                                    }).toList()
                                  // sort by last edited
                                  : shoppingList.map((prod) {
                                      bool isSelected = _selection.contains(prod.id!);
                                      bool isLastItem = shoppingList.indexOf(prod) == (shoppingList.length - 1);

                                      return _buildItem(prod, isSelected, isLastItem);
                                    }).toList()),
                    ),
                  // loading and search results widgets
                  Positioned(
                      child: Selector<ShoppingListsProvider, ({bool isSearching, List<Product> searchRes})>(
                    selector: (_, provider) => (isSearching: provider.isSearching, searchRes: provider.searchRes),
                    builder: (context, res, child) {
                      // loading
                      if (res.isSearching) {
                        return Container(
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0.0),
                            ),
                            child: loadingAnimation(context),
                          ),
                        );
                      }

                      // search results
                      if (res.searchRes.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0.0),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: res.searchRes.length,
                              itemBuilder: (BuildContext context, int index) {
                                Product prod = res.searchRes[index];

                                return InkWell(
                                  onTap: () {
                                    prod.isDone = false;
                                    String dateTime = DateTime.now().toUtc().toIso8601String();
                                    prod.lastEdited = dateTime;

                                    // check if the product exixst in the shopping list
                                    // this ensures products cannot be added twice
                                    bool isExists = false;
                                    for (var res in _listsProvider.shoppingList) {
                                      if (res.name == prod.name && res.categoryName == prod.categoryName) {
                                        isExists = true;
                                        break;
                                      }
                                    }

                                    List<String> membersForNotifs = [];
                                    membersForNotifs.addAll(_family.members.map((e) => e.address));
                                    membersForNotifs.remove(_authProvider.user!.address);
                                    if (!isExists) {
                                      _listsProvider.addProductsFromSearch(context, prod, _family.id, membersForNotifs);
                                    }
                                    _searchController.clear();
                                    _listsProvider.clearSearchRes();

                                    // remind user to add estimated price
                                    Future.delayed(const Duration(seconds: 2), () {
                                      snackBarHelper(context,
                                          message: "Please add estimated price for ${prod.name}",
                                          type: AnimatedSnackBarType.warning);
                                    });
                                  },
                                  child: Container(
                                    height: 60,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.5)))),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(prod.name ?? "",
                                              style: Theme.of(context).textTheme.bodyMedium,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(prod.categoryName?.titleCase ?? "",
                                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                                    overflow: TextOverflow.ellipsis)),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ))
                ],
              ),
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 100));
        });
  }

  Widget _loadingShimmer() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _demoList.map((prod) {
              bool isSelected = _selection.contains(prod.id!);

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 2, right: 4, left: 4),
                color: isSelected
                    ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
                    : Theme.of(context).colorScheme.onPrimary,
                child: ListTile(
                  leading: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        border:
                            Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5), width: 0.5)),
                  ),
                  title: Text(prod.name ?? "",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(decoration: prod.isDone == true ? TextDecoration.lineThrough : null)),
                ),
              );
            }).toList()),
      ),
    );
  }

  Widget _buildItem(Product prod, bool isSelected, bool isLastItem) {
    return FocusedMenuHolder(
      menuWidth: MediaQuery.of(context).size.width * 0.55,
      blurSize: 5.0,
      menuItemExtent: 45,
      menuBoxDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.5),
          borderRadius: const BorderRadius.all(Radius.circular(12.0))),
      duration: const Duration(milliseconds: 100),
      animateMenuItems: true,
      blurBackgroundColor: Theme.of(context).colorScheme.inverseSurface,
      openWithTap: false,
      menuOffset: 10.0,
      bottomOffsetHeight: 80,
      menuItems: [
        // view
        FocusedMenuItem(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(context.getString("home.view"), style: Theme.of(context).textTheme.titleSmall),
            trailingIcon: const Icon(Icons.remove_red_eye_outlined),
            onPressed: () async {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => DetailsScreen(product: prod, family: _family)));
            }),
        // select
        FocusedMenuItem(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(context.getString(isSelected ? "home.unselect" : "home.select"),
                style: Theme.of(context).textTheme.titleSmall),
            trailingIcon: const Icon(CommunityMaterialIcons.select_multiple),
            onPressed: () {
              if (!isSelected) {
                _selection.add(prod.id!);
              } else {
                _selection.remove(prod.id);
              }
              setState(() {
                isSelected = !isSelected;
              });
            }),
        // markComplete
        FocusedMenuItem(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
                prod.isDone != true ? context.getString("home.markComplete") : context.getString("home.markUncomplete"),
                style: Theme.of(context).textTheme.titleSmall),
            trailingIcon: const Icon(CommunityMaterialIcons.checkbox_marked_circle_outline),
            onPressed: () async {
              List<String> recipientIds = _family.members.map((e) => e.address).toList();
              recipientIds.remove(_authProvider.user!.address);

              String title = prod.isDone != true ? "Product marked as done" : "Product marked as undone";

              if (prod.isDone != true) {
                prod.isDone = true;
              } else {
                prod.isDone = false;
              }

              await _listsProvider.updateProduct(context, prod, _family.id);

              NotificationProvider().sendNotification(
                  title: title,
                  message: "${prod.name} | ${prod.categoryName} by ${_authProvider.user?.name}",
                  recipientIds: recipientIds);

              setState(() {});
            }),
        // delete
        FocusedMenuItem(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(context.getString("home.delete"),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red)),
            trailingIcon: const Icon(
              Icons.delete,
              color: Colors.redAccent,
            ),
            onPressed: () {
              platformDialog(
                  context: context,
                  title: context.getString("home.delete"),
                  message: context.getString("home.sureToDelete"),
                  onContinue: () async {
                    List<String> recipientIds = _family.members.map((e) => e.address).toList();
                    recipientIds.remove(_authProvider.user!.address);

                    await _listsProvider.deleteProduct(context,
                        product: prod,
                        familyId: _family.id,
                        recipientIds: recipientIds,
                        username: _authProvider.user!.name,
                        familyName: _family.name);
                  },
                  cancelText: context.getString("general.cancel"),
                  continueText: context.getString("general.continue"));
            }),
      ],
      onPressed: () async {
        if (_selection.isEmpty) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => DetailsScreen(product: prod, family: _family)));
        } else {
          if (isSelected) {
            _selection.remove(prod.id!);
          } else {
            _selection.add(prod.id!);
          }
          setState(() {});
        }
      },
      child: Container(
        width: double.infinity,
        margin: isLastItem ? null : const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: isSelected
            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
            : Theme.of(context).colorScheme.onPrimary,
        child: ListTile(
          // check box
          leading: Checkbox(
              value: prod.isDone,
              onChanged: (val) async {
                prod.isDone = val!;
                await _listsProvider.updateProduct(context, prod, _family.id);
                setState(() {});
              }),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // product name
              Text(prod.name ?? "",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(decoration: prod.isDone == true ? TextDecoration.lineThrough : null)),
              h4,
              // estimated price
              Text("${context.getString("home.estimatedPrice")}: ${prod.estimatedPrice ?? ""}",
                  style: Theme.of(context).textTheme.bodySmall),
              if (prod.isDone == true) h4,
              // actual price
              if (prod.isDone == true)
                Text("${context.getString("home.price")}: ${prod.actualPrice ?? ""}",
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          trailing:
              Visibility(visible: isSelected, child: const Icon(CommunityMaterialIcons.checkbox_marked_circle_outline)),
        ),
      ),
    );
  }
}
