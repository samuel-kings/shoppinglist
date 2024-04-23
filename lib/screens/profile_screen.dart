import 'dart:async';
import 'package:after_layout/after_layout.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:ez_localization/ez_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shoppinglist/helpers/widgets/leading_icon_btn.dart';
import 'package:shoppinglist/helpers/widgets/loading_animation.dart';
import 'package:shoppinglist/helpers/widgets/platform_dialog.dart';
import 'package:shoppinglist/helpers/widgets/sized_boxes.dart';
import 'package:shoppinglist/helpers/widgets/snackbar_helper.dart';
import 'package:shoppinglist/screens/auth_flow_screen.dart';
import 'package:shoppinglist/screens/category_mgmt_screen.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shoppinglist/screens/manage_familyscreen.dart';
import '../consts/img_consts.dart';
import '../helpers/widgets/custom_btn.dart';
import '../models/family.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  final String? returnRoute;
  const ProfileScreen({Key? key, this.returnRoute}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AfterLayoutMixin {
  String _selectedLocale = "en";

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = context.read<AuthProvider>();
    ThemeProvider themeProvider = context.read<ThemeProvider>();
    ThemeMode themeMode = context.watch<ThemeProvider>().themeMode;
    User user = authProvider.user!;
    Family family = authProvider.family!;

    List<({IconData icon, String name, Widget trailing, Function()? onTap})> drawerItems = [
      // family mgmgt
      (
        icon: CupertinoIcons.person_3,
        name: "profile.manageFam",
        trailing: const Icon(Icons.double_arrow),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageFamilyScreen()));
        }
      ),
      // categories mgmt
      (
        icon: Icons.category_outlined,
        name: "profile.catMgmt",
        trailing: const Icon(Icons.double_arrow),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryManagementScreen()))
      ),
      // change lang
      (
        icon: Icons.language,
        name: "profile.changeLang",
        onTap: () {
          List<({String id, String name, String img})> locales = [
            (id: "en", name: 'localeScreens.english', img: ImgConsts.english),
            (id: "fr", name: 'localeScreens.french', img: ImgConsts.french),
            (id: "es", name: 'localeScreens.spanish', img: ImgConsts.spanish),
            (id: "pt", name: 'localeScreens.portugese', img: ImgConsts.portugese),
            (id: "ru", name: 'localeScreens.russian', img: ImgConsts.russian)
          ];

          showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (context) {
                return StatefulBuilder(
                  builder: (BuildContext context, setState) {
                    return Container(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 0),
                      height: MediaQuery.of(context).size.height / 2.25,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // heading
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.getString("localeScreens.selectLang"),
                                  style: Theme.of(context).textTheme.titleMedium),
                              customButton(context, icon: Icons.done_all, text: context.getString("general.done"),
                                  onPressed: () {
                                context.read<AuthProvider>().saveLanguage(_selectedLocale);
                                snackBarHelper(context, message: context.getString("profile.changeLangSuccess"));
                                Navigator.of(context).pop();
                              })
                            ],
                          ),
                          h12,
                          // languages
                          Expanded(
                            child: ListView.builder(
                              itemCount: locales.length,
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (BuildContext context, int index) {
                                final locale = locales[index];
                                bool isSelected = _selectedLocale == locale.id;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedLocale = locale.id;
                                      EzLocalizationBuilder.of(context)!.changeLocale(Locale(locale.id));
                                      setState(
                                        () {},
                                      );
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                                value: isSelected,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _selectedLocale = locale.id;
                                                    EzLocalizationBuilder.of(context)!.changeLocale(Locale(locale.id));
                                                  });
                                                }),
                                            Text(context.getString(locale.name),
                                                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                                    color: isSelected
                                                        ? Theme.of(context).colorScheme.inversePrimary
                                                        : null)),
                                          ],
                                        ),
                                        Container(
                                          height: 60,
                                          width: 60,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(image: AssetImage(locale.img), fit: BoxFit.cover)),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ).animate().fadeIn(duration: const Duration(milliseconds: 100));
              });
        },
        trailing: const Icon(Icons.double_arrow),
      ),
      // change theme
      (
        icon: CommunityMaterialIcons.theme_light_dark,
        name: "profile.changeTheme",
        trailing: Selector<ThemeProvider, ThemeMode>(
          selector: (_, provider) => provider.themeMode,
          builder: (context, themeMode, child) {
            if (themeMode == ThemeMode.light) {
              return const Icon(Icons.light_mode_outlined);
            } else if (themeMode == ThemeMode.dark) {
              return const Icon(Icons.dark_mode_outlined);
            } else {
              return const Icon(Icons.computer);
            }
          },
        ),
        onTap: () async {
          if (themeMode == ThemeMode.light) {
            await themeProvider.changeTheme("dark");
          } else if (themeMode == ThemeMode.dark) {
            await themeProvider.changeTheme("system");
          } else {
            await themeProvider.changeTheme("light");
          }
        }
      ),
      // logout
      (
        icon: Icons.logout,
        name: "profile.logout",
        trailing: const Icon(Icons.double_arrow),
        onTap: () {
          platformDialog(
              cancelText: context.getString("general.cancel"),
              continueText: context.getString("general.continue"),
              context: context,
              title: context.getString("profile.logout"),
              message: context.getString("profile.logoutMessage"),
              onContinue: () async {
                await authProvider.logout();
                await Future.delayed(const Duration(milliseconds: 500));
                if (!context.mounted) return;
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AuthFlowScreen()));
              });
        }
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: leadingIcnBtn(context),
        title: Text(context.getString("profile.pageTitle"), style: Theme.of(context).textTheme.titleMedium),
      ),
      bottomNavigationBar: Container(
        height: 40,
        color: Colors.transparent,
        child: FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return loadingAnimation(context);
              }
    
              final info = snapshot.data as PackageInfo;
              final version = info.version;
    
              return Center(
                  child: Text("${context.getString("general.appVersion")} $version",
                      style: Theme.of(context).textTheme.bodySmall));
            }),
      ),
      body: Column(
        children: [
          // heading
          Center(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.person_circle,
                      size: 68,
                    ),
                    h12,
                    Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                    h4,
                    Text("FAMILY: ${family.name}", style: Theme.of(context).textTheme.titleSmall),
                  ],
                )),
          ),
          h4,
          const Divider(),
          h4,
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                children: drawerItems.map((item) {
              return InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: item.onTap,
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Icon(item.icon),
                    title: Text(context.getString(item.name), style: Theme.of(context).textTheme.titleSmall),
                    trailing: item.trailing,
                  ),
                ),
              );
            }).toList()),
          )
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    AuthProvider authProvider = context.read<AuthProvider>();
    _selectedLocale = await authProvider.getSavedLang();
    setState(() {});
  }
}
