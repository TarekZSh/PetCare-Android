import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Might be used by FCMService
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // If you still use it
import 'package:permission_handler/permission_handler.dart';
import 'package:pet_care_app/common/app_theme.dart';
import 'package:pet_care_app/services/fcm_service.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:device_info_plus/device_info_plus.dart'; // For Android version checks

import 'app_router.dart';
import 'providers/app_state_notifier.dart';
import 'providers/auth_provider.dart';
import 'services/notifications_service.dart';



Future<void> openExactAlarmSettings() async {
  const platform = MethodChannel('com.example.pet_care_app/alarm');
  try {
    await platform.invokeMethod('openExactAlarmSettings');
  } on PlatformException catch (e) {
    print("Failed to open exact alarm settings: ${e.message}");
  }
}

/// Requests normal permissions in a sequential manner (location, camera, storage).
Future<void> requestPermissionsSequentially() async {
  var locationStatus = await Permission.location.request();
  print("Location permission: $locationStatus");

  var cameraStatus = await Permission.camera.request();
  print("Camera permission: $cameraStatus");

  var storageStatus = await Permission.storage.request();
  print("Storage permission: $storageStatus");
}


/// Requests notification permission (Android & iOS).
Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    // If permanently denied or restricted, send user to settings:
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
    } else {
      // Request the permission (will show native dialog)
      await Permission.notification.request();
    }
  }
}

/// Request scheduleExactAlarm permission on Android 12+; it must be toggled via settings.
Future<void> requestExactAlarmPermissionIfNeeded() async {
  if (Platform.isAndroid) {
    final info = await DeviceInfoPlugin().androidInfo;
    // scheduleExactAlarm is only relevant on Android 12+ (SDK 31)
    if (info.version.sdkInt >= 31) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        // On many devices this can't be requested via a dialog;
        // we must send users to system settings:
        await openExactAlarmSettings();
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  // Initialize your AppStateNotifier
  final appStateNotifier = AppStateNotifier();
  appStateNotifier.initializeApp();

  await requestPermissionsSequentially();
  await requestNotificationPermission();
  await requestExactAlarmPermissionIfNeeded();

  // Initialize local notification & FCM
  await NotificationService.initialize();
  await FCMService.initialize();

  // Sequentially request permissions:
   // keep this last

  // Timezone initialization
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appStateNotifier),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(appStateNotifier: appStateNotifier),
        ),
      ],
      child: MyApp(appStateNotifier: appStateNotifier),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppStateNotifier appStateNotifier;
  const MyApp({super.key, required this.appStateNotifier});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Provider.of<AuthProvider>(context, listen: false).checkLoginState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading screen while waiting for login state
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    appTheme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          // Handle errors during login state check
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            ),
          );
        } else {
          // Build the main app with router configuration
          return MaterialApp.router(
            title: 'PetCare App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: MaterialColor(
                  0xFF249689,
                  <int, Color>{
                    50: Color(0xFFE0F2F1),
                    100: Color(0xFFB2DFDB),
                    200: Color(0xFF80CBC4),
                    300: Color(0xFF4DB6AC),
                    400: Color(0xFF26A69A),
                    500: Color(0xFF009688),
                    600: Color(0xFF00897B),
                    700: Color(0xFF00796B),
                    800: Color(0xFF00695C),
                    900: Color(0xFF004D40),
                  },
                ),
              ).copyWith(
                secondary: const Color(0xFF004D40),
              ),
            ),
            routerConfig: AppRouter.createRouter(appStateNotifier),
          );
        }
      },
    );
  }
}