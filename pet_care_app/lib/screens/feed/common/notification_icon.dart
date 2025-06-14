import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/feed/common/common_func.dart';
import 'package:pet_care_app/screens/feed/user_feed.dart';
import 'package:pet_care_app/screens/feed/notification.dart';

Widget buildNotificationsIcon(String currentUserId,  Map<String, Map<String, dynamic>> userCache ) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('notifications')
        .where('postOwnerId', isEqualTo: currentUserId) // Filter by user ID
        .where('seen', isEqualTo: false) // Only unseen notifications
        .snapshots(),
    builder: (context, snapshot) {
      int unseenCount = 0;
      print('unseen= ${unseenCount}');
      if (snapshot.hasData) {
        unseenCount = snapshot.data!.docs.length;
      }

      return Stack(
        children: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsPage(
                    currentUserId: currentUserId,
                    userCache: userCache, // Pass appropriate userCache if needed
                  ),
                ),
              );
            },
          ),
          if (unseenCount > 0)
            Positioned(
              right: 11,
              top: 11,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unseenCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    },
  );
}
