// import 'package:ez_localization/ez_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:shoppinglist/helpers/widgets/custom_btn.dart';
// import 'package:provider/provider.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// import '../../consts/img_consts.dart';
// import '../../consts/routes.dart';
// import '../../providers/auth_provider.dart';

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({Key? key}) : super(key: key);

//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   Future? _future;
//   final PageController _controller = PageController(initialPage: 0);
//   List<({String title, String desc, String img})> _intros = [];

//   @override
//   void initState() {
//     super.initState();
//     _future = Future.delayed(const Duration(seconds: 1));
//     _controller.addListener(() {
//       setState(() {});
//     });
//   }

//   Future<void> onFinished(BuildContext context) async {
//     var authProvider = context.read<AuthProvider>();
//     await authProvider.completeOnboarding();
//     if (mounted) context.go(Routes.authFlow);
//   }

//   @override
//   Widget build(BuildContext context) {
//     _intros = [
//       (
//         title: context.getString("onboarding.onboardingTitle1"),
//         desc: context.getString("onboarding.onboardingDesc1"),
//         img: ImgConsts.one
//       ),
//       (
//         title: context.getString("onboarding.onboardingTitle2"),
//         desc: context.getString("onboarding.onboardingDesc2"),
//         img: ImgConsts.two
//       ),
//       (
//         title: context.getString("onboarding.onboardingTitle3"),
//         desc: context.getString("onboarding.onboardingDesc3"),
//         img: ImgConsts.three
//       ),
//       (
//         title: context.getString("onboarding.onboardingTitle4"),
//         desc: context.getString("onboarding.onboardingDesc4"),
//         img: ImgConsts.four
//       )
//     ];

//     return Scaffold(
//         // skip btn
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           actions: [
//             FutureBuilder(
//               future: _future,
//               builder: (BuildContext context, AsyncSnapshot snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Container();
//                 } else {
//                   return Visibility(
//                     visible: _controller.page != _intros.length - 1,
//                     child: TextButton(
//                       onPressed: () => _controller.jumpToPage(_intros.length - 1),
//                       child: Text(context.getString("general.skip"), style: Theme.of(context).textTheme.titleSmall),
//                     ),
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//         bottomNavigationBar: AnimatedContainer(
//           duration: const Duration(milliseconds: 500),
//           curve: Curves.bounceInOut,
//           height: 160,
//           padding: const EdgeInsets.all(25),
//           width: MediaQuery.of(context).size.width,
//           color: Colors.transparent,
//           child: FutureBuilder(
//               future: _future,
//               builder: (BuildContext context, AsyncSnapshot snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Container();
//                 } else {
//                   return Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       // finish button
//                       Visibility(
//                           visible: _controller.page == _intros.length - 1,
//                           child: customButton(
//                             context,
//                             icon: Icons.double_arrow,
//                             text: context.getString("general.continue"),
//                             onPressed: () => onFinished(context),
//                           )),
//                       const Spacer(),
//                       // buttons and indicator
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           // back button
//                           Visibility(
//                             visible: _controller.page != 0,
//                             child: InkWell(
//                               onTap: () {
//                                 _controller.previousPage(
//                                     duration: const Duration(milliseconds: 500), curve: Curves.ease);
//                               },
//                               child: Container(
//                                 alignment: Alignment.center,
//                                 height: 40,
//                                 width: 40,
//                                 padding: const EdgeInsets.only(left: 5),
//                                 decoration: BoxDecoration(
//                                   color: Theme.of(context).colorScheme.primary,
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: const Center(child: Icon(Icons.arrow_back_ios, color: Colors.white)),
//                               ),
//                             ),
//                           ),
//                           const Spacer(),
//                           // page indicator
//                           SmoothPageIndicator(
//                               controller: _controller,
//                               count: _intros.length,
//                               effect: ExpandingDotsEffect(
//                                 activeDotColor: Theme.of(context).colorScheme.primary,
//                                 dotWidth: 10,
//                                 dotHeight: 10,
//                               ),
//                               onDotClicked: (index) {
//                                 _controller.animateToPage(index,
//                                     duration: const Duration(milliseconds: 500), curve: Curves.ease);
//                               }),
//                           const Spacer(),
//                           // next button
//                           Visibility(
//                             visible: _controller.page != _intros.length - 1,
//                             child: InkWell(
//                               onTap: () {
//                                 _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
//                               },
//                               child: Container(
//                                 alignment: Alignment.center,
//                                 height: 40,
//                                 width: 40,
//                                 padding: const EdgeInsets.only(left: 5),
//                                 decoration: BoxDecoration(
//                                   color: Theme.of(context).colorScheme.primary,
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: const Center(child: Icon(Icons.arrow_forward_ios, color: Colors.white)),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   );
//                 }
//               }),
//         ),
//         body: PageView.builder(
//           controller: _controller,
//           itemCount: _intros.length,
//           physics: const BouncingScrollPhysics(),
//           itemBuilder: (context, index) {
//             final intro = _intros[index];

//             return Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(children: [
//                 const SizedBox(
//                   height: 30,
//                 ),
//                 Center(
//                   child: Image.asset(
//                     intro.img,
//                     height: 300,
//                     width: 300,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 40,
//                 ),
//                 Text(intro.title, style: Theme.of(context).textTheme.titleLarge),
//                 const SizedBox(
//                   height: 10,
//                 ),
//                 Text(intro.desc, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
//               ]),
//             );
//           },
//         )).animate().fadeIn(duration: const Duration(milliseconds: 100));
//   }
// }
