import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:connection_notifier/connection_notifier.dart';
import 'package:ez_localization/ez_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shoppinglist/consts/notif_keys.dart';
import 'package:shoppinglist/helpers/utils/onesignal_config.dart';
import 'package:shoppinglist/screens/auth_flow_screen.dart';
import 'package:provider/provider.dart';
import 'package:shoppinglist/consts/prefs_consts.dart';
import 'package:shoppinglist/helpers/utils/sec_storage.dart';
import 'package:shoppinglist/providers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'firebase_options.dart';
import 'helpers/utils/color_schemes.dart';
import 'helpers/utils/text_theme.dart';
import 'providers/theme_provider.dart';

/// countryCode is declared as a global variable.
/// This is so it can be accessed and used to get the appropriate online/affline message
/// for the user (within the MyApp class).
String countryCode = "";

/// Initializing Onesignal, Firebase and Awesome Notifications
/// Onesignal is the push notification service
/// Firebase is used in this project for realtime database and storage services
/// Awesome Notifications is the local notifications service.
Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) WakelockPlus.enable();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  countryCode = await secStorage.read(key: PrefsConsts.language) ?? "en";
  OneSignal.shared.setAppId("4344420b-6f4f-41af-9763-ec2c852e3c5b");
  OneSignal.shared.promptUserForPushNotificationPermission();
  onesignalConfig(null, null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AwesomeNotifications().initialize(
      'resource://drawable/ic_stat_onesignal_default',
      [
        NotificationChannel(
            channelGroupKey: NotifKeys.reminderChannelGroup,
            channelKey: NotifKeys.reminderChannel,
            channelName: "Reminders",
            channelDescription: 'Reminders for shopping list items',
            defaultColor: const Color(0xFF006A66),
            ledColor: Colors.white),
        NotificationChannel(
            channelGroupKey: NotifKeys.taskAssignmentChannelGroup,
            channelKey: NotifKeys.taskAssignmentChannel,
            channelName: "Task Assignment",
            channelDescription: 'Notifications for when task have been assigned to user',
            defaultColor: const Color(0xFF006A66),
            ledColor: Colors.white),
      ],
      channelGroups: [
        NotificationChannelGroup(channelGroupKey: NotifKeys.reminderChannelGroup, channelGroupName: 'Reminders'),
        NotificationChannelGroup(
            channelGroupKey: NotifKeys.taskAssignmentChannelGroup, channelGroupName: 'Task Assignment')
      ],
      debug: false);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// For easy use of context navigation from local notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const String name = 'Opensort Shopping List';
  static const Color mainColor = Color(0xFF006A66);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // listen to changes/actions from local notifications
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: providers,
        child: ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
          builder: (context, child) {
            final themeMode = context.select<ThemeProvider, ThemeMode>((provider) => provider.themeMode);

            return EzLocalizationBuilder(
                delegate: const EzLocalizationDelegate(
                    supportedLocales: [Locale('en'), Locale('fr'), Locale('es'), Locale('pt'), Locale('ru')]),
                builder: (context, localizationDelegate) {
                  return ConnectionNotifier(
                    connectionNotificationOptions: ConnectionNotificationOptions(
                      disconnectedContent: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(getOnlineOfflineMessage(false),
                                style: GoogleFonts.montserrat(fontSize: 12), textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            alignment: Alignment.center,
                            height: 20,
                            width: 20,
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        ],
                      ),
                      connectedContent: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(getOnlineOfflineMessage(true),
                                style: GoogleFonts.montserrat(fontSize: 12), textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.check, color: Colors.white)
                        ],
                      ),
                    ),
                    child: MaterialApp(
                      title: MyApp.name,
                      navigatorKey: MyApp.navigatorKey,
                      color: MyApp.mainColor,
                      debugShowCheckedModeBanner: false,
                      themeMode: themeMode,
                      localizationsDelegates: localizationDelegate.localizationDelegates,
                      supportedLocales: localizationDelegate.supportedLocales,
                      localeResolutionCallback: localizationDelegate.localeResolutionCallback,
                      locale: const Locale("en"),
                      home: const AuthFlowScreen(),
                      theme: ThemeData(
                        useMaterial3: true,
                        colorScheme: lightColorScheme,
                        brightness: Brightness.light,
                        textTheme: lightTextTheme,
                      ),
                      darkTheme: ThemeData(
                          useMaterial3: true,
                          colorScheme: darkColorScheme,
                          brightness: Brightness.dark,
                          textTheme: darkTextTheme),
                    ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
                  );
                });
          },
        ));
  }
}

/// Get the online/offline message in the user's prefereed langauge
/// to be displayed by the connectivity widget.
String getOnlineOfflineMessage(bool isBackOnline) {
  Map<String, String> messages = {
    'en': isBackOnline ? '😃 Back Online' : '😣 You are currently offline',
    'fr': isBackOnline ? '😃 De retour en ligne' : '😣 Vous êtes actuellement hors ligne',
    'es': isBackOnline ? '😃 De vuelta en línea' : '😣 Actualmente estás desconectado',
    'pt': isBackOnline ? '😃 De volta online' : '😣 Você está atualmente offline',
    'ru': isBackOnline ? '😃 Онлайн снова' : '😣 Вы в настоящее время оффлайн'
  };
  return messages[countryCode]!;
}

/// Methods to perform custom actions for local notifications using the Awesome Notifications package
class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here

    // Navigate into pages, avoiding to open the notification details page over another details page already opened
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/notification-page', (route) => (route.settings.name != '/notification-page') || route.isFirst,
        arguments: receivedAction);
  }
}
