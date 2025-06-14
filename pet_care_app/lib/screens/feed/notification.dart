import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'post_detail_page.dart';
import 'common/common_func.dart';

class NotificationsPage extends StatelessWidget {
  final String currentUserId;
  final Map<String, Map<String, dynamic>> userCache;
  Logger logger = Logger();

  NotificationsPage({required this.currentUserId, required this.userCache});


Widget buildNotificationCard(BuildContext context, Map<String, dynamic> notification, String notificationId) {
  final senderId = notification['senderId'] ?? '';
  final postOwnerId = notification['postOwnerId'] ?? '';

  return FutureBuilder(
    future: Future.wait([
      fetchUserData(senderId, userCache),
      fetchUserData(postOwnerId, userCache),
    ]),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      final user = userCache[senderId] ?? {'name': 'Unknown User', 'imageUrl': ''};
      final senderImageUrl = user['imageUrl'] ?? user['profileImageUrl'] ?? '';
      final senderName = user['name'] ?? 'Unknown User';
      final title = (notification['type'] ?? '') == 'like' ? (notification['title'] ?? 'No Title') : (notification['body'] ?? 'No Body');
      final timestamp = (notification['timestamp'] as Timestamp?)?.toDate();
      final timeAgo = timestamp != null ? timeago.format(timestamp) : 'Unknown time';

      final isSeen = notification['seen'] == true;

return GestureDetector(
  onTap: () async {
    try {
      final postId = notification['postId'];
      final postOwnerId = notification['postOwnerId'];

      // Validate notification data
      if (postId == null || postOwnerId == null) {
        logger.e('Error: postId or postOwnerId is missing from notification: $notification');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("This post no longer exists.")),
        );
        return;
      }

      // Navigate to PostDetailPage FIRST before marking as seen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(
            postId: postId,
            postOwnerId: postOwnerId,
            currentUserId: currentUserId,
            userCache: userCache,
          ),
        ),
      );

      // Now mark the notification as seen AFTER the user has navigated
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'seen': true});

    } catch (e) {
      logger.e('Error processing notification or navigating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
    }
  },
        
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSeen ? Colors.white.withOpacity(0.9) : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: senderImageUrl.isNotEmpty
                    ? NetworkImage(senderImageUrl)
                    : user['role'] == 'vet' 
                        ? AssetImage('assets/images/vetProfile.png') as ImageProvider
                        : AssetImage('assets/images/petOwnerProfile.png') as ImageProvider,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


Widget buildNotificationList(BuildContext context, List<QueryDocumentSnapshot> notifications) {
  notifications.sort((a, b) {
    final aTimestamp = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
    final bTimestamp = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
    return bTimestamp.compareTo(aTimestamp); // Descending order
  });

  // Fetch all required user data before building the list
  return FutureBuilder(
    future: Future.wait(
      notifications.map((notificationDoc) {
        final notification = notificationDoc.data() as Map<String, dynamic>;
        final senderId = notification['senderId'] ?? '';
        final postOwnerId = notification['postOwnerId'] ?? '';
        return Future.wait([
          fetchUserData(senderId, userCache),
          fetchUserData(postOwnerId, userCache),
        ]);
      }),
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Center(
         // child: CircularProgressIndicator(),
        );
      }

      return ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notificationDoc = notifications[index];
          final notification = notificationDoc.data() as Map<String, dynamic>;
          final notificationId = notificationDoc.id; // Get the document ID

          return buildNotificationCard(context, notification, notificationId);
        },
      );
    },
  );
}


Widget noNotificationsWidget(BuildContext context) {
  return Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image from assets
          Image.asset(
            'assets/images/no_notifications.png', // Replace with your image path
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.6,
          ),
          const SizedBox(height: 20),
          // Text below the image
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "No notifications at the moment.",
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
        color: Colors.white,
      ),
      title: Text(
        'Notifications',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
        backgroundColor: Colors.green[900],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.blue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0x66000000),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('postOwnerId', isEqualTo: currentUserId)
                .snapshots(),
    
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data!.docs;

              if (notifications.isEmpty) {
               return noNotificationsWidget(context);
              }

              return buildNotificationList(context, notifications);
            },
          ),
        ),
      ),
    );
  }
}
