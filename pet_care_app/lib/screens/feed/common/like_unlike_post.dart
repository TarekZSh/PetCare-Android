import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'package:logger/logger.dart';

   Logger logger1 = Logger();

Future<void> addNotificationAndSaveToFirestore({
  required String recipientUserId, // The user who will receive the notification
  required String senderId,
  required String postLikes, // Number of likes on the post
  required String relatedPostId, // ID of the related post
  required String currentUserName,
}) async {
  if(recipientUserId == senderId){
    print('Cannot send notification to self.');
    return;
  }
  try {
    // Fetch the recipient's device token from Firestore
    final userRef = FirebaseFirestore.instance.collection('users').doc(recipientUserId);
    final userSnapshot = await userRef.get();
    final deviceToken = userSnapshot.data()?['deviceToken'];
    print('currentUserName: $currentUserName');
    // Save notification to Firestore
    await FirebaseFirestore.instance.collection('notifications').add({
      'postOwnerId': recipientUserId,
      'type': 'like',
      'title': '${currentUserName} liked your post!',
      'postId': relatedPostId,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
      'senderId' : senderId
    });

    // Send push notification if device token is available
    if (deviceToken != null) {
      await sendPushNotificationFeed(deviceToken, postLikes, relatedPostId,currentUserName);
    }

    logger1.i('Notification sent and saved successfully.');
  } catch (e) {
    logger1.i('Error in addNotificationAndSaveToFirestore: $e');
  }
}

Future<void> removeLikeNotifications(String postOwnerId, String postId, String currentUserId) async {
  if(postOwnerId == currentUserId){
    print('Cannot delete that was sent notification to self.');
    return;
  }
  final notificationsQuery = await FirebaseFirestore.instance
      .collection('notifications')
      .where('postOwnerId', isEqualTo: postOwnerId) // Post owner's userId
      .where('postId', isEqualTo: postId) // Post ID
      .where('type', isEqualTo: 'like') // Ensure it's a like notification
      .where('senderId', isEqualTo: currentUserId) // User who liked the post
      .get();

  for (var doc in notificationsQuery.docs) {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(doc.id)
        .delete();
  }
}

Future<void> sendPushNotificationFeed(
    String token, String postLikes, String chatId, String currentUserName) async {
  const String projectId = 'petcare-31013'; // Replace with your Firebase project ID
  final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

  // Path to your service account JSON key
  final serviceAccountKey =
      await rootBundle.loadString('assets/keys/keys-chat.json');

  final serviceAccount = jsonDecode(serviceAccountKey);

  final accountCredentials =
      ServiceAccountCredentials.fromJson(serviceAccount);

  // Obtain an OAuth 2 access token
  final client = await clientViaServiceAccount(accountCredentials, [
    'https://www.googleapis.com/auth/firebase.messaging',
  ]);

  // Prepare the notification payload
  final body = jsonEncode({
    'message': {
      'token': token,
      'notification': {
        'title': '${currentUserName} liked your post',
        'body': postLikes !='0' ? '${currentUserName} and ${postLikes} others liked your post' : '${currentUserName} liked your post',
      },
      'data': {
        'chatId': chatId,
      },
    },
  });

  // Send the notification
  final response = await client.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    print('Push notification sent successfully!');
  } else {
    print('Failed to send push notification: ${response.body}');
  }

  client.close(); // Close the HTTP client
}

Widget buildLikeButton({
  required Map<String, dynamic> post,
  required String currentUserId,
  required String currentUserName,
}) {
  
  return IconButton(
    icon: Icon(
      Icons.favorite,
      color: post['likedBy'] != null && post['likedBy'].contains(currentUserId)
          ? Colors.red
          : Colors.grey,
    ),
    onPressed: () async {
      try {
        final postRef =
            FirebaseFirestore.instance.collection('posts').doc(post['docId']);
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(post['userId']); // Reference to post owner's user data

        // Fetch the token of the user who posted
        final userSnapshot = await userRef.get();
        final userToken = userSnapshot.data()?['deviceToken'];
       // final postTitle = post['title'] ?? 'Your post'; // Post title or default

        if (post['likedBy'] != null &&
            post['likedBy'].contains(currentUserId)) {
          // Unlike the post
          await postRef.update({
            'likesCount': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([currentUserId]),
          });
          await removeLikeNotifications(post['userId'], post['docId'], currentUserId);
          print("Post unliked successfully.");
        } else {
          // Like the post
          await postRef.update({
            'likesCount': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([currentUserId]),
          });

          // Send notification
          //if (userToken != null) {
           await addNotificationAndSaveToFirestore(
    recipientUserId: post['userId'], // Post owner's userId
    senderId: currentUserId,
    postLikes: post['likesCount'].toString(),
    currentUserName: currentUserName,
    relatedPostId: post['docId'],
  );
          //}
          print("Post liked successfully.");
        }
      } catch (e) {
        print("Error while liking/unliking the post: $e");
      }
    },
  );
}


Future<void> handleLikeAction(
    String postId, Map<String, dynamic> post, String currentUserId) async {
  final postRef = FirebaseFirestore.instance
      .collection('posts')
      .doc(postId); // Use the document ID

  if (post['likedBy'] != null && post['likedBy'].contains(currentUserId)) {
    // Unlike the post
    await postRef.update({
      'likesCount': FieldValue.increment(-1),
      'likedBy': FieldValue.arrayRemove([currentUserId]),
    });
  } else {
    // Like the post
    await postRef.update({
      'likesCount': FieldValue.increment(1),
      'likedBy': FieldValue.arrayUnion([currentUserId]),
    });
  }
}