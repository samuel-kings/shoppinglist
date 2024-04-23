import 'dart:io';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:collection/collection.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:ez_localization/ez_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_date_utils/in_date_utils.dart';
import 'package:shoppinglist/consts/notif_keys.dart';
import 'package:shoppinglist/consts/prefs_consts.dart';
import 'package:shoppinglist/helpers/utils/pick_file.dart';
import 'package:shoppinglist/helpers/utils/sec_storage.dart';
import 'package:shoppinglist/helpers/utils/upload_img_to_fb.dart';
import 'package:shoppinglist/helpers/widgets/cached_network_image.dart';
import 'package:shoppinglist/helpers/widgets/loading_animation.dart';
import 'package:shoppinglist/helpers/widgets/platform_dialog.dart';
import 'package:shoppinglist/helpers/widgets/sized_boxes.dart';
import 'package:shoppinglist/helpers/widgets/snackbar_helper.dart';
import 'package:shoppinglist/models/category.dart';
import 'package:shoppinglist/models/family.dart';
import 'package:shoppinglist/providers/auth_provider.dart';
import 'package:shoppinglist/providers/notification_provider.dart';
import 'package:shoppinglist/providers/shopping_list_provider.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/utils/datetime_formatter.dart';
import '../models/product.dart';

class DetailsScreen extends StatefulWidget {
  final Product product;
  final Family family;
  const DetailsScreen({Key? key, required this.product, required this.family}) : super(key: key);

  @override
  DetailsScreenState createState() => DetailsScreenState();
}

class DetailsScreenState extends State<DetailsScreen> {
  late Product _product;
  late Family _family;
  DateTime? _selectedDate;
  File? _selectedFile;
  TextEditingController _noteController = TextEditingController();
  TextEditingController _titleController = TextEditingController();
  ShoppingListsProvider _provider = ShoppingListsProvider();
  TextEditingController _estimatedPriceController = TextEditingController();
  TextEditingController _actualPriceController = TextEditingController();

  bool _isChangesMade = false;

  bool _isScreenPopped = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ShoppingListsProvider>();
    _product = widget.product;
    _family = widget.family;
    _titleController = TextEditingController(text: _product.name);
    _product.priority ??= 1;
    _estimatedPriceController = TextEditingController(text: _product.estimatedPrice);
    _actualPriceController = TextEditingController(text: _product.actualPrice);

    _product.assignedTo ??= [];
    if (_product.remindAt != null) _selectedDate = DateTime.parse(_product.remindAt!).toLocal();
    if (_product.note != null) _noteController = TextEditingController(text: _product.note);
    _product.assignedTo ??= [];
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
    return PopScope(
        canPop: false,
        onPopInvoked: (_) async {
          _onExit();
        },
        child: Selector<ShoppingListsProvider, List<Product>>(
          selector: (_, provider) => _provider.shoppingList,
          builder: (context, shoppingList, child) {
            // on every change, update product
            int index = shoppingList.indexWhere((element) => element.id == _product.id);
            _product = shoppingList[index];
            // update family
            final List<String> memberIds = [];
            _family = context.read<AuthProvider>().family!;
            for (var member in _family.members) {
              memberIds.add(member.address);
            }

            return Scaffold(
                // name, title and back btn
                appBar: AppBar(
                  leading: IconButton(onPressed: () => _onExit(), icon: const Icon(Icons.arrow_back_ios)),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(_product.name!.titleCase,
                      //     style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                      SizedBox(
                        height: 45,
                        child: TextField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (val) {
                            _isChangesMade = true;
                          },
                          style: GoogleFonts.montserrat(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.5,
                          ),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                      ),
                      Text(_product.categoryName!.titleCase,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                      child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // change category
                        Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                        width: 0.5))),
                            child: InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                    context: context,
                                    enableDrag: true,
                                    showDragHandle: true,
                                    isScrollControlled: true,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setState_) {
                                          final categories = _provider.categories;
                                          categories.sortBy((element) => element.name.toLowerCase());

                                          return SingleChildScrollView(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                // title
                                                Center(
                                                  child: Text(context.getString("details.selectCat"),
                                                      style: Theme.of(context).textTheme.titleMedium),
                                                ),
                                                h20,
                                                // list
                                                ...categories.map((e) {
                                                  int index = categories.indexOf(e);

                                                  return InkWell(
                                                    onTap: () async {
                                                      // update product in shopping list
                                                      _product.categoryName = e.name;
                                                      _provider.updateProduct(context, _product, _family.id);

                                                      final cat = categories[index];
                                                      if (!cat.products.contains(_product.name)) {
                                                        _addProductToCat(_product.name!, cat);
                                                      }
                                                      _isChangesMade = true;
                                                      setState(() {});
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Column(
                                                      children: [
                                                        if (index != 0) const Divider(),
                                                        h4,
                                                        Center(
                                                            child: Text(e.name.titleCase,
                                                                style: Theme.of(context).textTheme.bodyMedium)),
                                                        h4
                                                      ],
                                                    ),
                                                  );
                                                }).toList()
                                              ]));
                                        },
                                      );
                                    });
                              },
                              child: ListTile(
                                leading: const Icon(Icons.edit_outlined),
                                // title text
                                title: Text(context.getString("details.category"),
                                    style: Theme.of(context).textTheme.bodyMedium),
                                subtitle: Text(context.getString("details.editCat"),
                                    style: Theme.of(context).textTheme.bodySmall),
                                // category
                                trailing: Text(_product.categoryName!.titleCase,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: Theme.of(context).colorScheme.primary)),
                              ),
                            )),
                        // assign
                        Container(
                            height: 60,
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                        width: 0.5))),
                            child: InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                    context: context,
                                    enableDrag: true,
                                    showDragHandle: true,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setState_) {
                                          bool isSelectAll = _product.assignedTo?.length == _family.members.length;

                                          return Container(
                                            height: 350,
                                            padding: const EdgeInsets.all(16).copyWith(top: 4, bottom: 0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // heading
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // text
                                                    Expanded(
                                                      child: Text(context.getString("details.assignTo"),
                                                          style: Theme.of(context).textTheme.titleSmall),
                                                    ),
                                                    // select all
                                                    Row(
                                                      children: [
                                                        Checkbox(
                                                            value: isSelectAll,
                                                            onChanged: (val) {
                                                              if (val!) {
                                                                _product.assignedTo = memberIds;

                                                                // alert assigned members
                                                                NotificationProvider().sendNotification(
                                                                    title: "New Item Assigned",
                                                                    message:
                                                                        "A new item was assigned to you.\nProduct: ${_product.name}, Category: ${_product.categoryName!.titleCase}.\nClick to view",
                                                                    recipientIds: _product.assignedTo!,
                                                                    data: {"product": _product, "family": _family});
                                                                _isChangesMade = true;
                                                              } else {
                                                                _product.assignedTo = [];
                                                              }
                                                              setState_(() {
                                                                isSelectAll = val;
                                                              });
                                                              setState(() {});
                                                            }),
                                                        Text("Select all",
                                                            style: Theme.of(context).textTheme.bodySmall),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                h16,
                                                // members
                                                ..._family.members.map((member) {
                                                  bool isHaveAccess = false;

                                                  if (_product.assignedTo != null) {
                                                    isHaveAccess = _product.assignedTo!.contains(member.address);
                                                  }

                                                  return Card(
                                                    child: ListTile(
                                                        leading: const Icon(
                                                          CupertinoIcons.person_circle,
                                                          size: 40,
                                                        ),
                                                        title: Text(member.name,
                                                            style: Theme.of(context).textTheme.bodyMedium),
                                                        trailing: Checkbox(
                                                            value: isHaveAccess,
                                                            onChanged: (val) {
                                                              _isChangesMade = true;
                                                              if (val!) {
                                                                _product.assignedTo = [
                                                                  ..._product.assignedTo!,
                                                                  member.address
                                                                ];
                                                                if (member.address !=
                                                                    context.read<AuthProvider>().user!.address) {
                                                                  // alert assigned member
                                                                  NotificationProvider().sendNotification(
                                                                      title: "New Item Assigned",
                                                                      message:
                                                                          "A new item was assigned to you.\nProduct: ${_product.name}, Category: ${_product.categoryName!.titleCase}.\nClick to view",
                                                                      recipientIds: [member.address],
                                                                      data: {"product": _product, "family": _family});
                                                                }
                                                              } else {
                                                                final temp = _product.assignedTo;
                                                                temp?.removeWhere(
                                                                    (element) => element == member.address);
                                                                _product.assignedTo = temp;
                                                              }
                                                              setState_(() {
                                                                isHaveAccess = val;
                                                              });
                                                              setState(() {});
                                                            })),
                                                  );
                                                }).toList()
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    });
                              },
                              child: ListTile(
                                leading: Container(
                                    height: 30,
                                    width: 30,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Theme.of(context).colorScheme.onBackground)),
                                    child: const Icon(
                                      Icons.people_alt_outlined,
                                      size: 20,
                                    )),
                                // title text
                                title: Text(context.getString("details.assignedTo"),
                                    style: Theme.of(context).textTheme.bodyMedium),
                                // assignee(s)
                                trailing: Text(
                                    _product.assignedTo == null || _product.assignedTo!.isEmpty
                                        ? context.getString("details.notAssigned")
                                        : _product.assignedTo?.length == _family.members.length
                                            ? context.getString("details.everyone")
                                            : _getAssignees(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: Theme.of(context).colorScheme.primary)),
                              ),
                            )),
                        // reminder
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5), width: 0.5))),
                          child: ListTile(
                            onTap: () async {
                              await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
                                if (!isAllowed) {
                                  platformDialog(
                                      context: context,
                                      title: context.getString("general.enableNotifsDialogTitle"),
                                      message: context.getString("general.enableNotifsDialogBody"),
                                      onContinue: () async {
                                        bool isGranted =
                                            await AwesomeNotifications().requestPermissionToSendNotifications();

                                        if (!context.mounted) return;
                                        if (isGranted) {
                                          snackBarHelper(context, message: context.getString("general.enabled"));
                                        } else {
                                          snackBarHelper(context,
                                              message: context.getString("general.disabled"),
                                              type: AnimatedSnackBarType.warning);
                                        }
                                      },
                                      onCancel: () => snackBarHelper(context,
                                          message: context.getString("general.disabled"),
                                          type: AnimatedSnackBarType.warning),
                                      cancelText: context.getString("general.cancel"),
                                      continueText: context.getString("general.enable"));
                                }
                              });

                              if (!context.mounted) return;

                              // select date
                              final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DTU.nextYear(DateTime.now()));

                              if (!context.mounted) return;

                              // select time
                              if (date != null) {
                                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());

                                if (!context.mounted) return;

                                if (time != null) {
                                  _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

                                  // set reminder
                                  try {
                                    await AwesomeNotifications().createNotification(
                                        content: NotificationContent(
                                          id: 0,
                                          channelKey: NotifKeys.reminderChannel,
                                          title: context.getString("details.reminder"),
                                          body:
                                              context.getString("details.reminderBody", {"productName": _product.name}),
                                          wakeUpScreen: true,
                                          category: NotificationCategory.Reminder,
                                          notificationLayout: NotificationLayout.Default,
                                        ),
                                        schedule:
                                            NotificationCalendar.fromDate(date: _selectedDate!, preciseAlarm: true));
                                    if (!context.mounted) return;

                                    // add reminder to local storage
                                    final idsString = await secStorage.read(key: PrefsConsts.notifiedIds);
                                    List<String> ids = [];
                                    if (idsString != null) ids = idsString.split(",");
                                    ids.add(_product.id!);
                                    await secStorage.write(key: PrefsConsts.notifiedIds, value: ids.join(","));

                                    if (!context.mounted) return;
                                    snackBarHelper(context, message: context.getString("details.reminderSet"));
                                  } on AwesomeNotificationsException catch (e) {
                                    debugPrint(e.toString());
                                    _selectedDate = null;
                                    if (!context.mounted) return;
                                    snackBarHelper(context, message: e.message, type: AnimatedSnackBarType.error);
                                  }

                                  _product.remindAt = _selectedDate?.toUtc().toIso8601String();
                                  _isChangesMade = true;

                                  setState(() {});
                                } else {
                                  snackBarHelper(context,
                                      message: context.getString("general.opsCancelled"),
                                      type: AnimatedSnackBarType.info);
                                }
                              }
                            },
                            leading: const Icon(CommunityMaterialIcons.calendar, size: 30),
                            title: _selectedDate == null
                                ? Text(context.getString("details.setReminder"),
                                    style: Theme.of(context).textTheme.bodyMedium)
                                : Text(getDateTime(_selectedDate ?? DateTime.now()),
                                    style: Theme.of(context).textTheme.bodyMedium),
                            trailing: _selectedDate != null
                                ? IconButton(
                                    onPressed: () {
                                      _selectedDate = null;
                                      setState(() {});
                                    },
                                    icon: Icon(Icons.cancel_outlined,
                                        size: 30, color: Theme.of(context).colorScheme.primary))
                                : Tooltip(
                                    triggerMode: TooltipTriggerMode.tap,
                                    message: context.getString("details.reminderTooltip"),
                                    child: const Icon(Icons.info_outlined)),
                          ),
                        ),
                        // photo
                        if (_selectedFile == null && _product.addedPhotoUrl == null)
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                        width: 0.5))),
                            child: ListTile(
                              onTap: () async => await _pickAndUploadImage(),
                              leading: const Icon(CommunityMaterialIcons.image_plus, size: 30),
                              title: Text(context.getString("details.addPhoto"),
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ),
                          )
                        else
                          InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                    context: context,
                                    showDragHandle: true,
                                    isScrollControlled: true,
                                    builder: (context) {
                                      List<({IconData icon, String title, Function onTap})> options = [
                                        // view
                                        (
                                          icon: Icons.remove_red_eye_outlined,
                                          title: context.getString("details.viewPhoto"),
                                          onTap: () async {
                                            final imageProvider = _product.addedPhotoUrl != null
                                                ? Image.network(_product.addedPhotoUrl!).image
                                                : Image.file(_selectedFile!).image;
                                            await showImageViewer(context, imageProvider);
                                            if (context.mounted) Navigator.of(context).pop();
                                          }
                                        ),
                                        // change
                                        (
                                          icon: Icons.change_circle_outlined,
                                          title: context.getString("details.changePhoto"),
                                          onTap: () async {
                                            final file = await pickFile();

                                            if (file != null && mounted) {
                                              setState(() {
                                                _selectedFile = file;
                                              });

                                              // delete existing
                                              final res = await deleteFileFromFirebase(_product.id!);

                                              if (res == null) {
                                                await Future.delayed(const Duration(seconds: 1));
                                                // upload new
                                                final record =
                                                    await uploadImageToFirebase(_selectedFile!, _product.id!);
                                                if (record.url != null) {
                                                  setState(() {
                                                    _product.addedPhotoUrl = record.url;
                                                    _isChangesMade = true;
                                                  });
                                                } else {
                                                  if (!context.mounted) return;
                                                  snackBarHelper(context,
                                                      message: record.error!, type: AnimatedSnackBarType.error);
                                                }
                                              } else {
                                                if (!context.mounted) return;
                                                snackBarHelper(context, message: res, type: AnimatedSnackBarType.error);
                                              }

                                              if (!context.mounted) return;
                                              Navigator.of(context).pop();
                                            }
                                          }
                                        ),
                                        // remove
                                        (
                                          icon: Icons.delete_outline,
                                          title: context.getString("details.deletePhoto"),
                                          onTap: () async {
                                            setState(() {
                                              _selectedFile = null;
                                              _product.addedPhotoUrl = null;
                                              _isChangesMade = true;
                                            });
                                            final res = await deleteFileFromFirebase(_product.id!);

                                            if (res == null) {
                                            } else {
                                              if (!context.mounted) return;
                                              snackBarHelper(context, message: res, type: AnimatedSnackBarType.error);
                                            }
                                            setState(() {});
                                            if (!context.mounted) return;
                                            Navigator.of(context).pop();
                                          }
                                        )
                                      ];

                                      return ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final option = options[index];

                                          return ListTile(
                                            onTap: () {
                                              option.onTap();
                                            },
                                            leading: Icon(option.icon),
                                            title: Text(option.title, style: Theme.of(context).textTheme.bodyMedium),
                                          );
                                        },
                                      );
                                    });
                              },
                              child: _selectedFile != null
                                  ? Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          image: DecorationImage(image: FileImage(_selectedFile!), fit: BoxFit.cover)),
                                    )
                                  : cnImage(_product.addedPhotoUrl!, const Size(double.infinity, 200))),
                        // priority
                        Container(
                            height: 60,
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                        width: 0.5))),
                            child: InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                    context: context,
                                    enableDrag: true,
                                    showDragHandle: true,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setState_) {
                                          final priorities = [
                                            {"title": "Low", "color": Colors.blue, "value": 1},
                                            {"title": "Medium", "color": Colors.orange, "value": 2},
                                            {"title": "High", "color": Colors.red, "value": 3}
                                          ];

                                          return Container(
                                            height: 200,
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // title
                                                Center(
                                                  child: Text(context.getString("details.selectPriority"),
                                                      style: Theme.of(context).textTheme.titleMedium),
                                                ),
                                                h20,
                                                // list
                                                ...priorities.map((e) {
                                                  int index = priorities.indexOf(e);

                                                  return InkWell(
                                                    onTap: () {
                                                      _product.priority = e["value"] as int;
                                                      _isChangesMade = true;
                                                      setState(() {});
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Column(
                                                      children: [
                                                        if (index != 0) const Divider(),
                                                        h4,
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            // color and text
                                                            Row(
                                                              children: [
                                                                // color
                                                                Container(
                                                                  height: 10,
                                                                  width: 10,
                                                                  decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      color: e["color"] as Color,
                                                                      border: Border.all(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .onBackground
                                                                              .withOpacity(0.5),
                                                                          width: 0.5)),
                                                                ),
                                                                w8,
                                                                // text
                                                                Text(e["title"] as String,
                                                                    style: Theme.of(context).textTheme.bodyMedium),
                                                              ],
                                                            ),
                                                            // checkmark
                                                            if (_product.priority == e["value"])
                                                              const Icon(Icons.check_circle, color: Colors.green)
                                                          ],
                                                        ),
                                                        h4
                                                      ],
                                                    ),
                                                  );
                                                }).toList()
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    });
                              },
                              child: ListTile(
                                leading: const Icon(CommunityMaterialIcons.flag_outline, size: 30),
                                // title text
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(context.getString("details.priority"),
                                        style: Theme.of(context).textTheme.bodyMedium),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          height: 10,
                                          width: 10,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _getPriorityColor(_product.priority!),
                                              border: Border.all(
                                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                                  width: 0.5)),
                                        ),
                                        w8,
                                        Text(_getPriority(_product.priority!),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(color: Theme.of(context).colorScheme.primary)),
                                      ],
                                    ),
                                  ],
                                ),
                                // priority
                              ),
                            )),
                        // estimated price
                        Container(
                            height: 60,
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                        width: 0.5))),
                            child: ListTile(
                              onTap: () {
                                showAdaptiveDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (ctx) {
                                      return PopScope(
                                          canPop: false,
                                          child: AlertDialog.adaptive(
                                            title: Text(
                                              context.getString("details.estimatedPrice"),
                                            ),
                                            content: SizedBox(
                                              height: 45,
                                              width: MediaQuery.of(context).size.width * 0.8,
                                              child: TextField(
                                                onChanged: (value) => _isChangesMade = true,
                                                inputFormatters: [
                                                  CurrencyTextInputFormatter.currency(
                                                      symbol: "₦",
                                                      locale: "en_NG",
                                                      decimalDigits: 0,
                                                      enableNegative: false)
                                                ],
                                                controller: _estimatedPriceController,
                                                keyboardType: TextInputType.number,
                                                style: GoogleFonts.montserrat(
                                                  color: Theme.of(context).colorScheme.onBackground,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 14,
                                                ),
                                                decoration: InputDecoration(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                    hintText: "Add estimated price",
                                                    hintStyle: GoogleFonts.montserrat(
                                                      color: Theme.of(context).colorScheme.onBackground,
                                                      fontWeight: FontWeight.w400,
                                                      fontSize: 14,
                                                    ),
                                                    border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onBackground
                                                                .withOpacity(0.5),
                                                            width: 0.5))),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                  },
                                                  child: Text(context.getString("general.cancel"))),
                                              TextButton(
                                                  onPressed: () {
                                                    _product.estimatedPrice = _estimatedPriceController.text.trim();

                                                    if (_product.estimatedPrice!.isEmpty) {
                                                      _product.estimatedPrice = null;
                                                    }

                                                    _isChangesMade = true;
                                                    setState(() {});
                                                    Navigator.of(ctx).pop();
                                                  },
                                                  child: Text(context.getString("general.done")))
                                            ],
                                          ));
                                    });
                              },
                              leading: const Icon(CommunityMaterialIcons.currency_usd_circle_outline, size: 30),
                              title: Text(context.getString("details.estimatedPrice"),
                                  style: Theme.of(context).textTheme.bodyMedium),
                              trailing: Text(_product.estimatedPrice ?? context.getString("details.notSet"),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(color: Theme.of(context).colorScheme.primary)),
                            )),
                        // actual price
                        Container(
                            height: 60,
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                        width: 0.5))),
                            child: ListTile(
                              onTap: () {
                                showAdaptiveDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (ctx) {
                                      return PopScope(
                                          canPop: false,
                                          child: AlertDialog.adaptive(
                                            title: Text(
                                              context.getString("details.price"),
                                            ),
                                            content: SizedBox(
                                              height: 45,
                                              width: MediaQuery.of(context).size.width * 0.8,
                                              child: TextField(
                                                onChanged: (value) => _isChangesMade = true,
                                                controller: _actualPriceController,
                                                inputFormatters: [
                                                  CurrencyTextInputFormatter.currency(
                                                      symbol: "₦",
                                                      locale: "en_NG",
                                                      decimalDigits: 0,
                                                      enableNegative: false)
                                                ],
                                                keyboardType: TextInputType.number,
                                                style: GoogleFonts.montserrat(
                                                  color: Theme.of(context).colorScheme.onBackground,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 14,
                                                ),
                                                decoration: InputDecoration(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                    hintText: "Add price",
                                                    hintStyle: GoogleFonts.montserrat(
                                                      color: Theme.of(context).colorScheme.onBackground,
                                                      fontWeight: FontWeight.w400,
                                                      fontSize: 14,
                                                    ),
                                                    border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onBackground
                                                                .withOpacity(0.5),
                                                            width: 0.5))),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                  },
                                                  child: Text(context.getString("general.cancel"))),
                                              TextButton(
                                                  onPressed: () {
                                                    _product.actualPrice = _actualPriceController.text.trim();

                                                    if (_product.actualPrice!.isEmpty) {
                                                      _product.actualPrice = null;
                                                    }

                                                    _isChangesMade = true;
                                                    setState(() {});
                                                    Navigator.of(ctx).pop();
                                                  },
                                                  child: Text(context.getString("general.done")))
                                            ],
                                          ));
                                    });
                              },
                              leading: const Icon(CommunityMaterialIcons.currency_usd_circle_outline, size: 30),
                              title: Text(context.getString("details.price"),
                                  style: Theme.of(context).textTheme.bodyMedium),
                              trailing: Text(_product.actualPrice ?? context.getString("details.notSet"),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(color: Theme.of(context).colorScheme.primary)),
                            )),
                        // note
                        ListTile(
                          titleAlignment: ListTileTitleAlignment.top,
                          leading: const Icon(CommunityMaterialIcons.note_text_outline, size: 30),
                          title: MarkdownBody(
                            data: _noteController.text.trim().isEmpty ? "Add a note here..." : _noteController.text,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                                p: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context).colorScheme.onBackground,
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400)),
                            onTapText: () {
                              showAdaptiveDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (ctx) {
                                    return PopScope(
                                        canPop: false,
                                        child: AlertDialog.adaptive(
                                          title: Text(_noteController.text.trim().isEmpty ? "Add a note" : "Edit note"),
                                          content: SizedBox(
                                            width: MediaQuery.of(context).size.width * 0.8,
                                            child: TextField(
                                              onChanged: (value) => _isChangesMade = true,
                                              controller: _noteController,
                                              textCapitalization: TextCapitalization.sentences,
                                              minLines: 2,
                                              maxLines: null,
                                              style: GoogleFonts.montserrat(
                                                color: Theme.of(context).colorScheme.onBackground,
                                                fontWeight: FontWeight.w400,
                                                height: 1.5,
                                                fontSize: 14,
                                              ),
                                              decoration: InputDecoration(
                                                  hintText: "Add a note",
                                                  hintStyle: GoogleFonts.montserrat(
                                                    color: Theme.of(context).colorScheme.onBackground,
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.5,
                                                    fontSize: 14,
                                                  ),
                                                  border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onBackground
                                                              .withOpacity(0.5),
                                                          width: 0.5))),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.of(ctx).pop();
                                                },
                                                child: Text(context.getString("general.cancel"))),
                                            TextButton(
                                                onPressed: () {
                                                  _product.note = _noteController.text.trim();
                                                  _isChangesMade = true;
                                                  Navigator.of(ctx).pop();
                                                },
                                                child: Text(context.getString("general.done")))
                                          ],
                                        ));
                                  });
                            },
                            onTapLink: (text, href, title) async {
                              if (href != null) {
                                launchUrl(Uri.parse(href));
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  )),
                ));
          },
        )).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }

  /// Pick and upload image to firebase
  Future<void> _pickAndUploadImage() async {
    final file = await pickFile();

    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    } else {
      return;
    }

    // show waiting dialog
    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(content: loadingAnimation(context));
        });

    final record = await uploadImageToFirebase(_selectedFile!, _product.id!);

    // close dialog
    if (mounted) Navigator.of(context).pop();

    if (record.url != null) {
      setState(() {
        _product.addedPhotoUrl = record.url;
      });
    } else {
      if (mounted) {
        snackBarHelper(context, message: record.error!, type: AnimatedSnackBarType.error);
      }
    }
  }

  /// Get list of assignees and concatenate them into a string
  String _getAssignees() {
    List<String> assigneesList = [];
    for (var id in _product.assignedTo!) {
      final member = _family.members.where((element) => element.address == id).first;
      assigneesList.add(member.name);
    }

    String assigneesString = assigneesList.join(",");
    return assigneesString;
  }

  /// a dialog to confirm if updated item should be permanently added to seleted cateogry
  void _addProductToCat(String productName, Category cat) {
    platformDialog(
        context: context,
        title: context.getString("details.editCatDialogTitle"),
        message: context
            .getString("details.editCatDialogBody", {"productName": productName, "categoryName": cat.name.titleCase}),
        onContinue: () {
          cat.products = [...cat.products, _product.name!.titleCase];
          _provider.updateCategory(context, cat, _family.id);
        },
        cancelText: context.getString("general.cancel"),
        continueText: context.getString("general.continue"));
  }

  /// save whatever was not been saved automatically on user exit
  void _onExit() {
    if (_isScreenPopped) return;

    // detect if changes were made
    if (!_isChangesMade) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _isScreenPopped = true;
        Navigator.of(context).pop();
      });
      return;
    }

    _product.remindAt = _selectedDate?.toUtc().toIso8601String();
    _product.note = _noteController.text.trim();
    _product.name = _titleController.text.trim();

    if (_product.name!.isEmpty) {
      snackBarHelper(context, message: context.getString("details.nameEmptyMessage"), type: AnimatedSnackBarType.error);
      return;
    }

    context.read<ShoppingListsProvider>().updateProduct(context, _product, _family.id);
    Future.delayed(const Duration(milliseconds: 100), () {
      _isScreenPopped = true;
      Navigator.of(context).pop();
    });
  }
}
