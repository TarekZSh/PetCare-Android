import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/common/app_theme.dart';
import 'package:pet_care_app/screens/feed/video_player/video_post_widget.dart';
import 'package:pet_care_app/screens/feed/common/common_func.dart';
import 'package:logger/logger.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final logger = Logger();

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String currentUserId;
 // final Map<String, dynamic> user;
  final Map<String, Map<String, dynamic>> userCache;

  PostDetailPage({
    required this.postId,
    required this.postOwnerId,
    required this.currentUserId,
    //required this.user,
    required this.userCache,
  });

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Map<String, dynamic>? post;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();
    if (snapshot.exists) {
      setState(() {
        post = snapshot.data() as Map<String, dynamic>;
      });
    } else {
      print("Post not found");
    }
  }

 Future<void> _fetchUserData(String userId, AuthProvider authProvider) async {
  if (!widget.userCache.containsKey(userId)) {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('vets')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        widget.userCache[userId] = {
          ...userDoc.data() as Map<String, dynamic>,
          'role': 'vet',
        };
        return;
      }

      userDoc = await FirebaseFirestore.instance
          .collection('pet_owners')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        widget.userCache[userId] = {
          ...userDoc.data() as Map<String, dynamic>,
          'role': 'pet_owner',
        };
      } else {
        widget.userCache[userId] = {
          'name': 'Unknown User',
          'imageUrl': '',
          'role': 'unknown',
        };
      }
    } catch (e) {
      widget.userCache[userId] = {
        'name': 'Unknown User',
        'imageUrl': '',
        'role': 'unknown',
      };
    }
  }
}


/////////////like and unlike///////// add notifiations
Widget buildLikeButton(Map<String, dynamic> post, AuthProvider authProvider) {
  print('aaaa');
  final userId = authProvider.petOwner?.id ?? authProvider.vet?.id;

  return IconButton(
    icon: Icon(
      Icons.favorite,
      color: post['likedBy'] != null && post['likedBy'].contains(userId)
          ? Colors.red
          : Colors.grey,
    ),
    onPressed: () => _toggleLike(authProvider),
  );
}

void _toggleLike(AuthProvider authProvider) async {
  final userId = authProvider.petOwner?.id ?? authProvider.vet?.id;
      if (! widget.userCache.containsKey(userId)) {
          await fetchUserData(userId!, widget.userCache);
        }
  final user = widget.userCache[userId] ??
                {'name': 'Unknown User', 'imageUrl': ''};
  String like = '';
  setState(() {
    if (post?['likedBy'] != null && post?['likedBy'].contains(userId)) {
      // User unlikes the post
      post?['likedBy'].remove(userId);
      post?['likesCount'] = (post?['likesCount'] ?? 1) - 1;
      like = 'unlike';
    } else {
      // User likes the post
      post?['likedBy'] = (post?['likedBy'] ?? [])..add(userId);
      post?['likesCount'] = (post?['likesCount'] ?? 0) + 1;
      like = 'like';
      print('okay?');
    }
  });

  try {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({
      'likesCount': post?['likedBy']!.contains(userId)
          ? FieldValue.increment(1)
          : FieldValue.increment(-1),
      'likedBy': post?['likedBy']!.contains(userId)
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    });

    // Send push notification
    if (like == 'like') {
      final postOwnerId = post?['userId'];
      if (postOwnerId != null /*&& postOwnerId != userId*/) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(postOwnerId);
        final userSnapshot = await userRef.get();
        final deviceToken = userSnapshot.data()?['deviceToken'];

        //if (deviceToken != null) {
          await addNotificationAndSaveToFirestore(
            recipientUserId: postOwnerId,
            senderId: userId!,
            title: '${user['name']} liked your post.',
            type: 'like',
            relatedPostId: widget.postId,
            currentUserName: user['name'],
            likeOrComment: post!['likesCount'].toString(),
            comment: '',
          );
        // }
        // else {
        //   print('Device token not found for the post owner.');
        // }
      }
    }
    else if (like == 'unlike') {
      await removeNotifications(post?['userId'], widget.postId, userId!,'like');
    }
  } catch (e) {
    print("Error toggling like: $e");
  }
}


Future<void> removeNotifications(String postOwnerId, String postId, String currentUserId, String type) async {
  if(postOwnerId == currentUserId)
  {
    print('Cannot remove notification for self.');
    return;
  }
  try {
    final notificationsQuery = await FirebaseFirestore.instance
        .collection('notifications')
        .where('postOwnerId', isEqualTo: postOwnerId) // Post owner's userId
        .where('postId', isEqualTo: postId) // Post ID
        .where('type', isEqualTo: type) // Correctly use the type parameter
        .where('senderId', isEqualTo: currentUserId) // User who created the comment
        .get();

    for (var doc in notificationsQuery.docs) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(doc.id)
          .delete();
    }

    print('Notification(s) removed successfully for type: $type');
  } catch (e) {
    print('Error in removeNotifications: $e');
  }
}

Future<void> editNotifications(String postOwnerId, String postId, String currentUserId, String type, String title) async {
 if(postOwnerId == currentUserId)
  {
    print('Cannot edit notification for self.');
    return;
  }

  try {
    final notificationsQuery = await FirebaseFirestore.instance
        .collection('notifications')
        .where('postOwnerId', isEqualTo: postOwnerId) // Post owner's userId
        .where('postId', isEqualTo: postId) // Post ID
        .where('type', isEqualTo: type) // Correctly use the type parameter
        .where('senderId', isEqualTo: currentUserId) // User who created the comment
        .get();

for (var doc in notificationsQuery.docs) {
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(doc.id)
      .update({
       'title': title, // Replace with the new title value
  });
}
    print('Notification(s) removed successfully for type: $type');
  } catch (e) {
    print('Error in removeNotifications: $e');
  }
}


Future<void> sendPushNotificationForLike( String token, String title, String body) async {
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
  final bodyPayload = jsonEncode({
    'message': {
      'token': token,
      'notification': {
        'title': title,
        'body': body,
      },
    },
  });

  // Send the notification
  final response = await client.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: bodyPayload,
  );

  if (response.statusCode == 200) {
    print('Push notification sent successfully!');
  } else {
    print('Failed to send push notification: ${response.body}');
  }

  client.close(); // Close the HTTP client
}

Future<void> addNotificationAndSaveToFirestore({
  required String recipientUserId, // The user who will receive the notification
  required String senderId,
  required String title,
  required String type, // Notification type (e.g., "like", "comment")
  required String relatedPostId, // ID of the related post
  required String currentUserName,
  required String likeOrComment,
  required String comment,
}) async {
  if (recipientUserId == senderId) {
    print('Cannot send notification to self.');
    return;
  }
  
  try {
    // Fetch the recipient's device token from Firestore
    final userRef = FirebaseFirestore.instance.collection('users').doc(recipientUserId);
    final userSnapshot = await userRef.get();
    final deviceToken = userSnapshot.data()?['deviceToken'];
    String body = '';
     if(type == 'like') {
        body =  likeOrComment !='0' ? '${currentUserName} and ${likeOrComment} others liked your post' : '${currentUserName} liked your post';
      }
      else if(type == 'comment') {
       body =  '${currentUserName} commented: $comment';
      }
    // Save notification to Firestore
    await FirebaseFirestore.instance.collection('notifications').add({
      'postOwnerId': recipientUserId,
      'type': type,
      'title': title,
      'postId': relatedPostId,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
      'senderId' : senderId,
      'body': body
    });

    // Send push notification if device token is available
    if (deviceToken != null) {
      if(type == 'like') {
        await sendPushNotificationForLike(deviceToken, title, body);
      }
      else if(type == 'comment') {
        await sendPushNotificationForComment(deviceToken, title, body);
      }
    }

    print('Notification sent and saved successfully.');
  } catch (e) {
    print('Error in addNotificationAndSaveToFirestore: $e');
  }
}









//////////////add comment //////////// add notificatoins
  Future<void> _addComment(AuthProvider authProvider) async {

  if (_commentController.text.trim().isEmpty) return;
  try {
    final userId = authProvider.petOwner?.id ?? authProvider.vet?.id;
    if (! widget.userCache.containsKey(userId)) {
          await fetchUserData(userId!, widget.userCache);
        }
    final user = widget.userCache[userId] ??
                {'name': 'Unknown User', 'imageUrl': ''};
    String userRole = authProvider.petOwner != null ? 'pet_owner' : 'vet';
    final comment = {
      'userId': userId,
      'userRole': userRole,
      'text': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Add comment to Firestore
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add(comment);

    // Update comments count in the post
    setState(() {
      post?['commentsCount'] = (post?['commentsCount'] ?? 0) + 1;
    });

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'commentsCount': FieldValue.increment(1),
    });
    final commentText = _commentController.text.trim();
    _commentController.clear();

    // Fetch the post owner's token
    final postOwnerId = post?['userId']; // Ensure `userId` field is available in the post data
    if (postOwnerId != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(postOwnerId);
      final userSnapshot = await userRef.get();
      final deviceToken = userSnapshot.data()?['deviceToken'];

      // Send notification if token is available
      //if (deviceToken != null) {
        await addNotificationAndSaveToFirestore(
            recipientUserId: postOwnerId,
            senderId: userId!,
            title: '${user['name']} commented on your post.',
            type: 'comment',
            relatedPostId: widget.postId,
            currentUserName: user['name'],
            likeOrComment: '',
            comment: comment['text'] as String,
          );
      //}
    }
  } catch (e) {
    print("Error adding comment: $e");
  }
}




Future<void> sendPushNotificationForComment(
    String token, String title, String body) async {
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
  final bodyPayload = jsonEncode({
    'message': {
      'token': token,
      'notification': {
        'title': title,
        'body': body,
      },
    },
  });

  // Send the notification
  final response = await client.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: bodyPayload,
  );

  if (response.statusCode == 200) {
    print('Push notification sent successfully!');
  } else {
    print('Failed to send push notification: ${response.body}');
  }

  client.close(); // Close the HTTP client
}



///////////////////////////appBar////////////////////
  AppBar buildPostDetailsAppBar() {
    return AppBar(
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      backgroundColor: Colors.green[900],
      title: Text(
        "Post Details",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

////////////building the post////////////////////////////
  Widget _buildHeader(Map<String, dynamic> post, Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                user['imageUrl'] != null && user['imageUrl'].isNotEmpty
                    ? NetworkImage(user['imageUrl'])
                    : user['profileImageUrl'] != null &&
                            user['profileImageUrl'].isNotEmpty
                        ? NetworkImage(user['profileImageUrl'])
                        : post['userRole'] == 'vet'
                            ? AssetImage('assets/images/vetProfile.png')
                                as ImageProvider
                            : AssetImage('assets/images/petOwnerProfile.png')
                                as ImageProvider,
            backgroundColor: Colors.grey[200],
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                post['timestamp'] != null
                    ? timeago
                        .format(
                          (post['timestamp'] as Timestamp).toDate(),
                          locale: 'en_short',
                        )
                        .replaceFirst('~', '')
                         .replaceAll(' ago', '') // Remove "ago"
                    : "Unknown time",
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 15.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget buildPostContent(Map<String, dynamic>? post) {
  if (post == null) return SizedBox.shrink();

  final media = post['media'] as List<dynamic>?; // Ensure this is a list
  final PageController pageController = PageController();
  int currentPageIndex = 0;

  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post['caption'] != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                post['caption'] ?? "",
                style: TextStyle(fontSize: 20),
              ),
            ),

          // Media Content
          if (media != null && media.isNotEmpty)
            Column(
              children: [
                SizedBox(
                  height: 300, // Fixed height for the media carousel
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: media.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentPageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final mediaItem = media[index] as Map<String, dynamic>;
                      final isVideo = mediaItem['isVideo'] == 'true'; // Adjust if needed
                      final url = mediaItem['url'] ?? '';

                      return isVideo
                          ? SizedBox(
                              width: double.infinity, // Expand to full width
                              child: VideoPostWidget(videoUrl: url),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                url,
                                height: 300,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                    },
                  ),
                ),

                // Indicator Dots
                 if (media.length > 1) ...[
                      SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(media.length, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentPageIndex == index ? Colors.blue : Colors.grey,
                      ),
                    );
                  }),
                ),
                 ],
              ],
            ),
        ],
      );
    },
  );
}


  Widget _buildLikeAndCommentSection(
      Map<String, dynamic> post, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          buildLikeButton(post, authProvider),
          GestureDetector(
            onTap: () {
              if (post['likedBy'] != null && post['likedBy'].isNotEmpty) {
                showLikesModal(
                  context: context,
                  likedBy: post['likedBy'],
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("No likes to display.")),
                );
              }
            },
            child: Text(
              "${post['likesCount'] ?? 0} likes",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(width: 16),
          Icon(Icons.comment, color: Colors.grey),
          SizedBox(width: 4),
          Text(
            "${post['commentsCount'] ?? 0} comments",
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

//////////end building post //////////////////

//////////////////comments section/////////////////
  Widget buildCommentsSection(String postId, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Comments",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .orderBy('timestamp', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final comments = snapshot.data!.docs;

            if (comments.isEmpty) {
              return _buildNoCommentsMessage();
            }
            return _buildCommentsList(comments, authProvider);
          },
        ),
      ],
    );
  }

  Widget _buildNoCommentsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no_comments.png',
            width: 200,
            height: 200,
          ),
          SizedBox(height: 12),
          Text(
            "Be the first to comment",
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(
      List<DocumentSnapshot> comments, AuthProvider authProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final commentDoc = comments[index];
        final comment = commentDoc.data() as Map<String, dynamic>;

        return FutureBuilder<void>(
          future: _fetchUserData(comment['userId'], authProvider),
          builder: (context, snapshot) {
            final user = widget.userCache[comment['userId']] ??
                {'name': 'Unknown User', 'imageUrl': ''};

            return _buildCommentItem(
              comment: comment,
              user: user,
              commentId: commentDoc.id,
              currentUserId: widget.currentUserId,
              postOwnerId: widget.postOwnerId,
              onEdit: (commentId) {
                final initialText = comment['text'];
                _editComment(commentId, initialText, user, comment['userRole']);
              },
              onDelete: (commentId) {
                _deleteComment(commentId);
              },
            );
          },
            );
      },
    );
  }

  Widget _buildCommentItem({
    required Map<String, dynamic> comment,
    required Map<String, dynamic> user,
    required String commentId,
    required String currentUserId,
    required String postOwnerId,
    required Function(String) onEdit,
    required Function(String) onDelete,
  }) {
    //bool isVet = comment['userRole'] == 'vet';
    return GestureDetector(
      onTap: () {
        if (comment['userId'] != currentUserId &&
            postOwnerId == currentUserId) {
          _showCommentOptions(
            context,
            commentId,
            false,
            /*comment owner*/
            onEdit,
            onDelete,
          );
        }
        if (comment['userId'] == currentUserId) {
          _showCommentOptions(
            context,
            commentId,
            true,
            /*comment owner*/
            onEdit,
            onDelete,
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Stack(
  children: [
    Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: comment['userRole'] == 'vet'
            ? Border.all(color: Colors.lightBlue, width: 3) // Gold border for vets
            : null,
      ),
      child: CircleAvatar(
        radius: 24.0,
        backgroundImage: user['imageUrl'] != null && user['imageUrl'].isNotEmpty
            ? NetworkImage(user['imageUrl'])
            : user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty
                ? NetworkImage(user['profileImageUrl'])
                : comment['userRole'] == 'vet'
                    ? AssetImage('assets/images/vetProfile.png') as ImageProvider
                    : AssetImage('assets/images/petOwnerProfile.png') as ImageProvider,
      ),
    ),
    
    if (comment['userRole'] == 'vet') // Show vet icon only for vets
      Positioned(
        bottom: 0, 
        right: 0, 
        child: Container(
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue, // Matches border color
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: FaIcon(
            FontAwesomeIcons.stethoscope, // Vet-related icon
            color: Colors.white,
            size: 14, // Adjusted for smaller avatar
          ),
        ),
      ),
  ],
),

            SizedBox(width: 12.0),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        Text(
                          comment['timestamp'] != null
                              ? timeago
                                  .format(
                                    (comment['timestamp'] as Timestamp)
                                        .toDate(),
                                    locale: 'en_short',
                                  )
                                  .replaceFirst('~', '')
                                   .replaceAll(' ago', '') // Remove "ago"
                              : "Unknown time",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      comment['text'],
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentOptions(
    BuildContext context,
    String commentId,
    bool commentOwner,
    Function(String) onEdit,
    Function(String) onDelete,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (commentOwner == true)
              ListTile(
                leading: Icon(Icons.edit, color: Colors.grey),
                title: Text("Edit Comment"),
                onTap: () {
                  Navigator.pop(context);
                  onEdit(commentId);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.grey),
              title: Text("Delete Comment"),
              onTap: () {
                Navigator.pop(context);
                onDelete(commentId);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentInputSection(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Write a comment...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey[200],
                filled: true,
              ),
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.send, color: appTheme.of(context).success),
            onPressed: () => _addComment(authProvider),
          ),
        ],
      ),
    );
  }
//////////////////end comments section/////////////////

/////////////////edit and delete comments/////////////
  void _editComment(String commentId, String initialText,
      Map<String, dynamic> user, String userRole) {
    TextEditingController _controller =
        TextEditingController(text: initialText);
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // User photo on the left
                      CircleAvatar(
                        backgroundImage: user['imageUrl'] != null &&
                                user['imageUrl'].isNotEmpty
                            ? NetworkImage(user['imageUrl'])
                            : user['profileImageUrl'] != null &&
                                    user['profileImageUrl'].isNotEmpty
                                ? NetworkImage(user['profileImageUrl'])
                                : userRole == 'vet'
                                    ? AssetImage('assets/images/vetProfile.png')
                                        as ImageProvider
                                    : AssetImage(
                                            'assets/images/petOwnerProfile.png')
                                        as ImageProvider,
                        radius: 20.0,
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _controller,
                              maxLines: null,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: BorderSide(
                                    color: errorMessage != null
                                        ? Colors.red
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                hintText: "Edit your comment",
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              style: TextStyle(fontSize: 14.0),
                            ),
                            if (errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12.0),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Cancel", style: TextStyle(fontSize: 18.0)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          String updatedText = _controller.text.trim();
                          if (updatedText.isEmpty) {
                            setState(() {
                              errorMessage = "Comment cannot be empty!";
                            });
                            return;
                          }

                          try {
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(widget.postId)
                                .collection('comments')
                                .doc(commentId)
                                .update({'text': updatedText});
                            Navigator.pop(context);

                            await editNotifications(widget.postOwnerId, widget.postId, widget.currentUserId,'comment','${user['name']} commented: "$updatedText"'); //mays
                          } catch (e) {
                            print("Error updating comment: $e");
                            setState(() {
                              errorMessage =
                                  "Failed to update comment. Please try again.";
                            });
                          }
                        },
                        child: Text("Save Changes",
                            style: TextStyle(fontSize: 18.0)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteComment(String commentId) async {
    //delete notification
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Comment"),
          content: Text("Are you sure you want to delete this comment?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId)
            .delete();

        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update({
          'commentsCount': FieldValue.increment(-1),
        });
      
        await removeNotifications(widget.postOwnerId, widget.postId, widget.currentUserId,'comment'); //mays

        setState(() {
          post?['commentsCount'] = (post?['commentsCount'] ?? 1) - 1;
        });
      } catch (e) {
        print('Error deleting comment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment')),
        );
      }
    }
  }

 @override
Widget build(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  return Scaffold(
    appBar: buildPostDetailsAppBar(),
    body: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final postData = snapshot.data!.data() as Map<String, dynamic>?;

        if (postData == null) {
          return Center(
            child: Text("Post not found or deleted.", style: TextStyle(color: Colors.red)),
          );
        }

        // Retrieve the user data from cache or fetch it
        if (!widget.userCache.containsKey(postData['userId'])) {
          fetchUserData(postData['userId'], widget.userCache);
        }

        final user = widget.userCache[postData['userId']] ?? {'name': 'Unknown User', 'imageUrl': ''};

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(postData, user), // Header Section
                    buildPostContent(postData), // Content Section
                    Divider(color: Colors.grey[200]),
                    _buildLikeAndCommentSection(postData, authProvider), // Like and Comment Section
                    buildCommentsSection(widget.postId, authProvider), // Comments Section
                  ],
                ),
              ),
            ),
            _buildCommentInputSection(authProvider), // Comment Input Section
          ],
        );
      },
    ),
  );
}

}