import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care_app/screens/feed/video_player/video_post_widget.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:pet_care_app/screens/feed/post_detail_page.dart';
import 'package:pet_care_app/screens/feed/common/common_func.dart';
import 'package:logger/logger.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final logger = Logger();

Widget buildPostList({
  required List<DocumentSnapshot> posts,
  required Map<String, Map<String, dynamic>> userCache,
  required BuildContext context,
  required String currentUserId,
  required Function(bool) setLoading,
}) {
 fetchUserData(currentUserId, userCache);
  return Column(
    children: List.generate(
      posts.length,
      (index) {
        final postDoc = posts[index];
        final post = postDoc.data() as Map<String, dynamic>;
        final postId = postDoc.id;
        post['docId'] = postId;
final postOwnerId = post['userId'];
return FutureBuilder(
           future: fetchUserData(postOwnerId, userCache),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState != ConnectionState.done &&
                !userCache.containsKey(postOwnerId)) {
            }
            final user = userCache[postOwnerId] ?? {
              'name': 'Unknown User',
              'imageUrl': '',
            };
            final currentUser = userCache[currentUserId] ?? {
              'name': 'Unknown User',
              'imageUrl': '',
            };
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailPage(
                      postId: postId,
                     // user: user,
                      postOwnerId: postOwnerId,
                      currentUserId: currentUserId,
                      userCache: userCache,
                    ),
                  ),
                );
              },
              child: buildPostCard(
                post: post,
                user: user,
                currentUserId: currentUserId,
                currentUserName: currentUser['name'],
                onLikePressed: () async {
                  await handleLikeAction(postId, post, currentUserId);
                },
                onPostPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(
                        postId: postId,
                       // user: user,
                        postOwnerId: postOwnerId,
                        currentUserId: currentUserId,
                        userCache: userCache,
                      ),
                    ),
                  );
                },
                context: context,
                setLoading: setLoading,
              ),
            );
          },
        );
      },
    ),
      );
}



Widget buildPostCard({
  required Map<String, dynamic> post,
  required Map<String, dynamic> user,
  required String currentUserId,
  required String currentUserName,
  required Function onLikePressed,
  required Function onPostPressed,
  required BuildContext context,
  required Function(bool) setLoading,
}) {
  final PageController pageController = PageController();
  int currentPageIndex = 0;

  return StatefulBuilder(
    builder: (context, setState) {
      bool isVet = post['userRole'] == 'vet';

      return Card(
        color: Colors.grey[290],
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Stack(
  children: [
    Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isVet
            ? Border.all(color: Colors.lightBlue, width: 4) // Gold border for vets
            : null,
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundImage: user['imageUrl'] != null && user['imageUrl'].isNotEmpty
            ? NetworkImage(user['imageUrl'])
            : user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty
                ? NetworkImage(user['profileImageUrl'])
                : isVet
                    ? AssetImage('assets/images/vetProfile.png') as ImageProvider
                    : AssetImage('assets/images/petOwnerProfile.png') as ImageProvider,
      ),
    ),
    
    if (isVet) // Only show icon for vets
      Positioned(
        bottom: 0, 
        right: 0, 
        child: Container(
          padding: EdgeInsets.all(4),
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

                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user['name'] != null && user['name'].length > 20
                                    ? '${user['name'].substring(0, 20)}...'
                                    : user['name'] ?? 'Unknown User',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                             
                            ],
                          ),
                          Text(
                            post['timestamp'] != null
                                ? timeago
                                    .format((post['timestamp'] as Timestamp).toDate())
                                    .replaceFirst('~', '') // Remove tilde (~)
                                    .replaceAll(' ago', '') // Remove "ago"
                                : 'Unknown time',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
    if (currentUserId == post['userId']) // Show menu if user owns the post
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            handleEditPost(
              context: context,
              post: post,
              setLoading: setLoading,
            );
          } else if (value == 'delete') {
            handleDeletePost(
              context: context,
              postId: post['docId'],
            );
          }
        },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.grey),
                SizedBox(width: 12),
                Text(
                  'Edit post',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.grey),
                SizedBox(width: 12),
                Text(
                  'Delete post',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        icon: Icon(Icons.more_vert),
                    )
                ],
              ),
              // Post caption
              if (post['caption'] != null && post['caption'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    post['caption'],
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              // Post media
              if (post['media'] != null && post['media'].isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: post['media'].length,
                        onPageChanged: (index) {
                          setState(() {
                            currentPageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final media = post['media'][index];
                          final mediaUrl = media['url'];
                          final isVideo = media['isVideo'] == 'true';

                          return isVideo
                              ? VideoPostWidget(videoUrl: mediaUrl)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    mediaUrl,
                                    height: 250,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                );
                        },
                      ),
                    ),
                    
                    
                    if (post['media'].length > 1) ...[
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(post['media'].length, (index) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentPageIndex == index ? Colors.green : Colors.grey,
                            ),
                          );
                        }),
                      ),
                    ],
                    
                  ],
                ),
              Divider(color: Colors.grey[400]),
              Row(
                children: [
                  buildLikeButton(post: post, currentUserId: currentUserId, currentUserName: currentUserName),
                  GestureDetector(
                    onTap: () {
                      if (post['likedBy'] != null && post['likedBy'].isNotEmpty) {
                        // Show likes modal if there are likes
                        showLikesModal(context: context, likedBy: post['likedBy']);
                      } else {
                        // Show no likes modal if there are no likes
                        showNoLikesModal(context: context);
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
                  IconButton(
                    icon: Icon(Icons.comment, color: Colors.grey),
                    onPressed: () => onPostPressed(),
                  ),
                  Text("${post['commentsCount'] ?? 0}"),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


Widget buildNoPostsAvailableMessage() {
  return Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              double size = MediaQuery.of(context).size.shortestSide / 2;
              return Center(
                child: Image.asset(
                  'assets/images/no_posts.png',
                  height: size,
                  width: size,
                  fit:
                      BoxFit.contain, 
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Text(
            "Oops! Nothing to see here...",
            style: TextStyle(
              fontSize: 24, 
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth,
                child: Text(
                  "Looks like your pets are camera shy 🐾",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          SizedBox(height: 10),
          Text(
            "Why not share your pet's adorable moments?",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
        ],
      ),
    ),
  );
}

