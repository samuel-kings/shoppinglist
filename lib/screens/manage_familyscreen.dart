import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:ez_localization/ez_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shoppinglist/helpers/widgets/leading_icon_btn.dart';
import 'package:shoppinglist/helpers/widgets/platform_dialog.dart';
import 'package:shoppinglist/helpers/widgets/snackbar_helper.dart';
import 'package:shoppinglist/models/family.dart';
import 'package:shoppinglist/models/user.dart';
import 'package:shoppinglist/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../helpers/utils/datetime_formatter.dart';

class ManageFamilyScreen extends StatefulWidget {
  const ManageFamilyScreen({Key? key}) : super(key: key);

  @override
  State<ManageFamilyScreen> createState() => _ManageFamilyScreenState();
}

class _ManageFamilyScreenState extends State<ManageFamilyScreen> {
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = context.read<AuthProvider>();
    User user = authProvider.user!;

    return PopScope(
      canPop: false,
      onPopInvoked: (_) async {
        Navigator.of(context).pop();
      },
      child: Scaffold(
          appBar: AppBar(
            leading: leadingIcnBtn(context),
            title: Text(context.getString("manage.pageTitle"), style: Theme.of(context).textTheme.titleMedium),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                    onTapDown: (details) async {
                      final RenderBox referenceBox = context.findRenderObject() as RenderBox;
                      final Offset tapPosition = referenceBox.globalToLocal(details.globalPosition);

                      final RenderObject? overlay = Overlay.of(context).context.findRenderObject();

                      final positionRelativeToButton = RelativeRect.fromRect(
                          Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 30, 30),
                          Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height));

                      final selected = await showMenu(context: context, position: positionRelativeToButton, items: [
                        // head
                        PopupMenuItem(
                            value: 0,
                            child: Text(context.getString("manage.invite"),
                                style: Theme.of(context).textTheme.titleSmall)),
                        // copy
                        PopupMenuItem(
                            value: 1,
                            child: SizedBox(
                              width: 400,
                              child: Row(
                                children: [
                                  const Icon(Icons.copy),
                                  const SizedBox(width: 10),
                                  Text(context.getString("manage.copy"), style: Theme.of(context).textTheme.titleSmall),
                                ],
                              ),
                            )),
                        // share
                        PopupMenuItem(
                            value: 2,
                            child: Row(
                              children: [
                                const Icon(Icons.share),
                                const SizedBox(width: 10),
                                Text(context.getString("manage.share"), style: Theme.of(context).textTheme.titleSmall),
                              ],
                            )),
                      ]);

                      if (context.mounted) {
                        switch (selected) {
                          case 0:
                            break;
                          case 1:
                            await Clipboard.setData(ClipboardData(
                                text: context.getString("manage.shareMessage", {"familyId": user.familyId})));
                            if (context.mounted) snackBarHelper(context, message: context.getString("general.copied"));
                            break;
                          case 2:
                            if (!context.mounted) return;
                            Share.share(context.getString("manage.shareMessage", {"familyId": user.familyId}));
                            break;
                          default:
                        }
                      }
                    },
                    child: const Icon(Icons.more_vert)),
              )
            ],
          ),
          body: SingleChildScrollView(
              padding: const EdgeInsets.all(20).copyWith(bottom: 0),
              child: Selector<AuthProvider, Family?>(
                selector: (_, provider) => provider.family,
                builder: (context, family, child) {
                  return Column(
                    children: family!.members.map((member) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            CupertinoIcons.person_circle,
                            size: 40,
                          ),
                          title: Text(member.name, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text(
                              "${context.getString("manage.joined")}: ${getDateTime(DateTime.parse(member.createdAt))}",
                              style: Theme.of(context).textTheme.bodySmall),
                          trailing: member.address == family.creator
                              ? const Tooltip(
                                  message: "Admin",
                                  child: Icon(Icons.admin_panel_settings),
                                )
                              : Visibility(
                                  visible: family.creator == user.address,
                                  child: IconButton(
                                      onPressed: () async {
                                        platformDialog(
                                          cancelText: context.getString("general.cancel"),
                                          continueText: context.getString("general.continue"),
                                          context: context,
                                          title: context.getString("manage.removeDialogTitle"),
                                          message: context.getString("manage.removeDialogMessage"),
                                          onContinue: () async {
                                            final success = await authProvider.removeMember(member.address);
                                            if (!context.mounted) return;
                                            if (success) {
                                              snackBarHelper(context,
                                                  message: context.getString("manage.removeSuccessful"));
                                              setState(() {});
                                            } else {
                                              snackBarHelper(context,
                                                  message: context.getString(authProvider.error),
                                                  type: AnimatedSnackBarType.error);
                                              setState(() {});
                                            }
                                          },
                                        );
                                      },
                                      icon: const Icon(CupertinoIcons.delete, color: Colors.red)),
                                ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ))).animate().fadeIn(duration: const Duration(milliseconds: 400)),
    );
  }
}
