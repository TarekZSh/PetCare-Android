import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care_app/services/notifications_service.dart';

class FCMService with WidgetsBindingObserver {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static bool isAppInForeground = false; // Tracks if the app is in the foreground

  static Future<void> initialize() async {
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(FCMService());

    // Request notification permissions
    await _requestPermissions();

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _saveTokenToServer(newToken);
    });

    // Handle foreground and background notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (isAppInForeground) {
        print('App is in foreground. Suppressing notification.');
        // Optionally handle the data if you want to update the UI
      } else {
        print('App is in background. Showing notification.');
        if (message.notification != null) {
          NotificationService.showLocalNotification(
            id: message.hashCode,
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? '',
          );
        }
      }
    });

    // Handle notification clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked: ${message.data}');
      _handleNotificationClick(message);
    });

    // Get the FCM token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    if (token != null) {
      _saveTokenToServer(token);
    }
  }

  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Notification permission status: ${settings.authorizationStatus}');
  }

  static Future<void> _saveTokenToServer(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'deviceToken': token,
        }, SetOptions(merge: true));
        print('Device token saved: $token');
      } else {
        print('No user is currently signed in. Token not saved.');
      }
    } catch (e) {
      print('Error saving token to Firestore: $e');
    }
  }

  static void _handleNotificationClick(RemoteMessage message) {
    if (message.data.containsKey('chatId')) {
      final chatId = message.data['chatId'];
      print('Navigating to chat with ID: $chatId');
      // Add navigation logic here
    }
  }

  // Lifecycle methods to track app state
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      isAppInForeground = true;
      print('App is in foreground.');
    } else {
      isAppInForeground = false;
      print('App is in background.');
    }
  }

  static void dispose() {
    WidgetsBinding.instance.removeObserver(FCMService());
  }
}
