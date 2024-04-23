import 'package:collection/collection.dart';
import 'package:ez_localization/ez_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoppinglist/helpers/widgets/custom_btn.dart';
import 'package:shoppinglist/helpers/widgets/platform_dialog.dart';
import 'package:shoppinglist/helpers/widgets/sized_boxes.dart';
import 'package:shoppinglist/models/category.dart';
import 'package:shoppinglist/providers/auth_provider.dart';
import 'package:shoppinglist/providers/shopping_list_provider.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShoppingListsProvider>();
    final familyId = context.read<AuthProvider>().family!.id;
    TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_ios_new)),
        title: Text(context.getString("manageCats.title"), style: Theme.of(context).textTheme.titleMedium),
        centerTitle: true,
      ),
      // create new category button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (context) {
                return StatefulBuilder(
                  builder: (BuildContext context, setState_) {
                    bool isLoading = false;

                    return SingleChildScrollView(
                        padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: Column(
                          children: [
                            // heading
                            Text(context.getString("manageCats.add"), style: Theme.of(context).textTheme.titleMedium),
                            h20,
                            // textfield
                            SizedBox(
                              height: 55,
                              child: TextField(
                                autofocus: true,
                                controller: controller,
                                textCapitalization: TextCapitalization.sentences,
                                style: GoogleFonts.montserrat(
                                  color: Theme.of(context).colorScheme.onBackground,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ),
                            h8,
                            // done btn
                            customButton(context,
                                isLoading: isLoading,
                                icon: Icons.done_all,
                                text: context.getString("general.done"), onPressed: () async {
                              String text = controller.text.trim();

                              if (text.isNotEmpty) {
                                setState_(() {
                                  isLoading = true;
                                });

                                await provider.createNewCategory(context, text, familyId);

                                setState_(() {
                                  isLoading = false;
                                });
                              }
                              setState(() {});
                              if (context.mounted) Navigator.of(context).pop();
                            }),
                            h12
                          ],
                        ));
                  },
                );
              });
        },
        icon: const Icon(Icons.add),
        label: Text(context.getString("manageCats.new"), style: Theme.of(context).textTheme.titleSmall),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Selector<ShoppingListsProvider, List<Category>>(
          selector: (_, provider) => provider.categories,
          builder: (context, categories, child) {
            categories.sortBy((element) => element.name.toLowerCase());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categories.map((e) {
                int index = categories.indexOf(e);
                int count = e.products.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index != 0) const Divider(),
                    ListTile(
                      title: Text(e.name.titleCase, style: Theme.of(context).textTheme.bodyMedium),
                      subtitle: Text("$count product(s)", style: Theme.of(context).textTheme.bodySmall),
                      trailing: Visibility(
                        visible: e.isCustomCategory,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // edit
                            IconButton.outlined(
                                onPressed: () {
                                  controller = TextEditingController(text: e.name);

                                  showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
                                      isScrollControlled: true,
                                      builder: (context) {
                                        return StatefulBuilder(
                                          builder: (BuildContext context, setState_) {
                                            bool isLoading = false;

                                            return SingleChildScrollView(
                                                padding: const EdgeInsets.all(16)
                                                    .copyWith(bottom: MediaQuery.of(context).viewInsets.bottom),
                                                child: Column(
                                                  children: [
                                                    // heading
                                                    Text(context.getString("manageCats.edit"),
                                                        style: Theme.of(context).textTheme.titleMedium),
                                                    h20,
                                                    // textfield
                                                    SizedBox(
                                                      height: 55,
                                                      child: TextField(
                                                        autofocus: true,
                                                        controller: controller,
                                                        textCapitalization: TextCapitalization.sentences,
                                                        style: GoogleFonts.montserrat(
                                                          color: Theme.of(context).colorScheme.onBackground,
                                                          fontWeight: FontWeight.w400,
                                                          height: 1.5,
                                                          fontSize: 14,
                                                        ),
                                                        decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12))),
                                                      ),
                                                    ),
                                                    h8,
                                                    // done btn
                                                    customButton(context,
                                                        isLoading: isLoading,
                                                        icon: Icons.done_all,
                                                        text: context.getString("general.done"), onPressed: () async {
                                                      String text = controller.text.trim();

                                                      if (text.isNotEmpty && e.name != text) {
                                                        setState_(() {
                                                          isLoading = true;
                                                        });

                                                        e.name = text;

                                                        await provider.updateCategory(context, e, familyId);

                                                        setState_(() {
                                                          isLoading = false;
                                                        });
                                                      }
                                                      setState(() {});
                                                      if (context.mounted) Navigator.of(context).pop();
                                                    }),
                                                    h12
                                                  ],
                                                ));
                                          },
                                        );
                                      });
                                },
                                icon: const Icon(Icons.edit_outlined)),
                            // delete
                            IconButton.outlined(
                                onPressed: () {
                                  platformDialog(
                                      context: context,
                                      title: context.getString("manageCats.delete"),
                                      message: context.getString("manageCats.deleteConfirm"),
                                      onContinue: () async {
                                        await provider.deleteCategory(context, e, familyId);
                                        setState(() {});
                                      },
                                      cancelText: context.getString("general.cancel"),
                                      continueText: context.getString("general.done"));
                                },
                                icon: const Icon(Icons.delete_outline))
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 100));
  }
}
