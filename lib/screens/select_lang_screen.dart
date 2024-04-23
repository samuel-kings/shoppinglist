import 'dart:async';
import 'package:after_layout/after_layout.dart';
import 'package:ez_localization/ez_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shoppinglist/consts/img_consts.dart';
import 'package:shoppinglist/helpers/widgets/custom_btn.dart';
import 'package:shoppinglist/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shoppinglist/screens/auth_flow_screen.dart';
import '../helpers/widgets/sized_boxes.dart';

/// select app language on first time app launch
class SelectLangScreen extends StatefulWidget {
  const SelectLangScreen({Key? key}) : super(key: key);

  @override
  State<SelectLangScreen> createState() => _SelectLangScreenState();
}

class _SelectLangScreenState extends State<SelectLangScreen> with AfterLayoutMixin {
  /// default: "en"
  String _selectedLocale = "en";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration:
            const BoxDecoration(image: DecorationImage(image: AssetImage(ImgConsts.shoppingListBg), fit: BoxFit.fill)),
        child: Container(
          padding: const EdgeInsets.only(left: 20),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.getString("localeScreens.welcome"),
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white)),
              h8,
              Text(context.getString("localeScreens.getStarted"),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Colors.white, fontWeight: FontWeight.normal)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 100));
  }

  /// automically fires the bottom modal sheet or screen launch
  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    /// language codes, names and images
    List<({String id, String name, String img})> locales = [
      (id: "en", name: 'localeScreens.english', img: ImgConsts.english),
      (id: "fr", name: 'localeScreens.french', img: ImgConsts.french),
      (id: "es", name: 'localeScreens.spanish', img: ImgConsts.spanish),
      (id: "pt", name: 'localeScreens.portugese', img: ImgConsts.portugese),
      (id: "ru", name: 'localeScreens.russian', img: ImgConsts.russian)
    ];

    showModalBottomSheet(
        context: context,
        enableDrag: false,
        showDragHandle: false,
        isDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) {
          return PopScope(
            canPop: false,
            onPopInvoked: (_) async {},
            child: StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Container(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 0),
                  height: MediaQuery.of(context).size.height / 2.5,
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
                            Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(builder: (context) => const AuthFlowScreen()));
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
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
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
                                                color:
                                                    isSelected ? Theme.of(context).colorScheme.inversePrimary : null)),
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
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 400), duration: const Duration(milliseconds: 400));
        });
  }
}
