import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppStateNotifier extends ChangeNotifier {
  bool _showSplashImage = true;
  User? _currentUser;

  bool get showSplashImage => _showSplashImage;
  bool get isLoggedIn => _currentUser != null;

  void updateUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void stopShowingSplashImage() {
    _showSplashImage = false;
    notifyListeners();
  }

  Future<void> initializeApp() async {
    try {
      await Future.wait([
        Future.delayed(Duration(seconds: 2)), // Simulated delay
        FirebaseAuth.instance.authStateChanges().first,
      ]);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        updateUser(user);
        await saveDeviceToken(user.uid);
        monitorFCMToken(user.uid);
      }
    } catch (e) {
      print('Error during initialization: $e');
    } finally {
      stopShowingSplashImage();
    }
  }

  /// Save the FCM device token to Firestore
  Future<void> saveDeviceToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'deviceToken': token,
        }, SetOptions(merge: true));
        print('Device token saved: $token');
      }
    } catch (e) {
      debugPrint('Error saving device token: $e');
    }
  }

  /// Monitor for FCM token updates
  void monitorFCMToken(String userId) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await saveDeviceToken(userId);
      print('Token updated and saved: $newToken');
    });
  }
}
