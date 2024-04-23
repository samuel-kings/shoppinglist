import 'package:ez_localization/ez_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shoppinglist/helpers/widgets/custom_btn.dart';
import 'package:shoppinglist/helpers/widgets/sized_boxes.dart';
import 'package:shoppinglist/screens/onboarding/create_or_join_family_screen.dart';

class CreateAccountNameScreen extends StatelessWidget {
  const CreateAccountNameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    FocusNode node = FocusNode();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // heading
            Text(context.getString("createAcctNameScreen.heading"), style: Theme.of(context).textTheme.titleMedium),
            h16,
            // form
            Form(
                key: formKey,
                child: AutofillGroup(
                  child: TextFormField(
                    controller: controller,
                    focusNode: node,
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
                        hintText: "John Doe",
                        hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).hintColor),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                )),
            h16,
            // continue button
            customButton(context, icon: Icons.double_arrow, text: context.getString("general.continue"), onPressed: () {
              if (formKey.currentState!.validate()) {
                node.unfocus();
                TextInput.finishAutofillContext();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CreateOrJoinFamilyScreen(name: controller.text.trim())));
              }
            })
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 100));
  }
}
