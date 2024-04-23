import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:ez_localization/ez_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shoppinglist/helpers/widgets/custom_btn.dart';
import 'package:shoppinglist/helpers/widgets/snackbar_helper.dart';
import 'package:shoppinglist/models/family.dart';
import 'package:shoppinglist/models/user.dart';
import 'package:shoppinglist/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shoppinglist/screens/auth_flow_screen.dart';
import '../../helpers/utils/id_gen.dart';
import '../../helpers/widgets/sized_boxes.dart';

class CreateOrJoinFamilyScreen extends StatefulWidget {
  final String name;
  const CreateOrJoinFamilyScreen({Key? key, required this.name}) : super(key: key);

  @override
  State<CreateOrJoinFamilyScreen> createState() => _CreateOrJoinFamilyScreenState();
}

class _CreateOrJoinFamilyScreenState extends State<CreateOrJoinFamilyScreen> {
  String get name => widget.name;
  AuthProvider _authProvider = AuthProvider();

  final _createFormKey = GlobalKey<FormState>();
  final _createController = TextEditingController();
  final FocusNode _createNode = FocusNode();
  bool _createLoading = false;

  final _joinFormKey = GlobalKey<FormState>();
  final _joinController = TextEditingController();
  final FocusNode _joinNode = FocusNode();
  bool _joinLoading = false;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // create
              customButton(context,
                  icon: CupertinoIcons.person_3,
                  text: context.getString("createOrJoinScreen.createFam"), onPressed: () {
                showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (_) {
                      return SingleChildScrollView(
                        child: StatefulBuilder(
                          builder: (BuildContext context, setState) {
                            return Container(
                              padding:
                                  const EdgeInsets.all(20).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // heading
                                  Text(context.getString("createOrJoinScreen.famName"),
                                      style: Theme.of(context).textTheme.titleMedium),
                                  h16,
                                  // form
                                  Form(
                                      key: _createFormKey,
                                      child: AutofillGroup(
                                        child: TextFormField(
                                          controller: _createController,
                                          focusNode: _createNode,
                                          textInputAction: TextInputAction.done,
                                          keyboardType: TextInputType.name,
                                          autofillHints: const [AutofillHints.name],
                                          validator: (value) {
                                            if (value == null || value.isEmpty || value.length < 3) {
                                              return context.getString("general.validator");
                                            } else {
                                              return null;
                                            }
                                          },
                                          style: Theme.of(context).textTheme.bodySmall,
                                          decoration: InputDecoration(
                                              hintText: "Family Name",
                                              hintStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(color: Theme.of(context).hintColor),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                        ),
                                      )),
                                  h16,
                                  customButton(context,
                                      icon: Icons.done_all,
                                      isLoading: _createLoading,
                                      text: context.getString("general.done"), onPressed: () async {
                                    if (_createFormKey.currentState!.validate()) {
                                      setState(() {
                                        _createLoading = true;
                                      });
                                      FocusScope.of(context).unfocus();
                                      _createNode.unfocus();
                                      TextInput.finishAutofillContext();

                                      String famId = generateId();
                                      String uId = generateId();
                                      User user = User(
                                          address: uId,
                                          familyId: famId,
                                          name: name,
                                          createdAt: DateTime.now().toUtc().toIso8601String());
                                      Family family = Family(
                                          id: famId,
                                          members: [user],
                                          creator: uId,
                                          name: _createController.text.trim());
                                      final success = await _authProvider.createFamily(user, family);

                                      setState(() {
                                        _createLoading = false;
                                      });

                                      if (!context.mounted) return;

                                      if (success) {
                                        snackBarHelper(context,
                                            message: context.getString("createOrJoinScreen.success"));
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(builder: (context) => const AuthFlowScreen()));
                                      } else {
                                        snackBarHelper(context,
                                            message: _authProvider.error, type: AnimatedSnackBarType.error);
                                      }
                                    }
                                  }),
                                  h12
                                ],
                              ),
                            );
                          },
                        ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
                      );
                    });
              }),
              h20,
              // join
              customButton(context,
                  icon: CupertinoIcons.person_add,
                  text: context.getString("createOrJoinScreen.joinFam"), onPressed: () {
                showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (_) {
                      return SingleChildScrollView(
                        child: StatefulBuilder(
                          builder: (BuildContext context, setState) {
                            return Container(
                              padding:
                                  const EdgeInsets.all(20).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // heading
                                  Text(context.getString("createOrJoinScreen.familyId"),
                                      style: Theme.of(context).textTheme.titleMedium),
                                  h16,
                                  // form
                                  Form(
                                      key: _joinFormKey,
                                      child: TextFormField(
                                        controller: _joinController,
                                        focusNode: _joinNode,
                                        textInputAction: TextInputAction.done,
                                        keyboardType: TextInputType.text,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return context.getString("general.emptyValidator");
                                          } else {
                                            return null;
                                          }
                                        },
                                        style: Theme.of(context).textTheme.bodySmall,
                                        decoration: InputDecoration(
                                            hintText: "Family ID or link",
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(color: Theme.of(context).hintColor),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                      )),
                                  h16,
                                  customButton(context,
                                      icon: Icons.done_all,
                                      isLoading: _joinLoading,
                                      text: context.getString("general.done"), onPressed: () async {
                                    if (_joinFormKey.currentState!.validate()) {
                                      // unfocus text   field
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        _joinLoading = true;
                                      });
                                      _createNode.unfocus();
                                      TextInput.finishAutofillContext();

                                      final success =
                                          await _authProvider.joinFamily(context, name, _joinController.text.trim());

                                      setState(() {
                                        _joinLoading = false;
                                      });

                                      if (!context.mounted) return;

                                      if (success) {
                                        snackBarHelper(context,
                                            message: context.getString("createOrJoinScreen.success"));
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(builder: (context) => const AuthFlowScreen()));
                                      } else {
                                        snackBarHelper(context,
                                            message: _authProvider.error, type: AnimatedSnackBarType.error);
                                      }
                                    }
                                  }),
                                  h12
                                ],
                              ),
                            );
                          },
                        ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
                      );
                    });
              })
            ],
          )),
    ).animate().fadeIn(duration: const Duration(milliseconds: 100));
  }
}
