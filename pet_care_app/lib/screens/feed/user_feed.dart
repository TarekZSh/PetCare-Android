import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/feed/common/common_func.dart';

class UserFeed extends StatefulWidget {
  //final List<DocumentSnapshot> posts;

  UserFeed();

  @override
  _UserFeedState createState() => _UserFeedState();
}

class _UserFeedState extends State<UserFeed> {
  final Map<String, Map<String, dynamic>> userCache = {}; 

    bool _isLoading = false; 

void setLoading(bool value) {
  if (mounted) {
    setState(() {
      _isLoading = value;
    });
  }
}


@override
Widget build(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context);

  final currentUserId = authProvider.petOwner != null
      ? authProvider.petOwner!.id
      : authProvider.vet!.id;

  Future<void> _refreshUserFeed() async {
    setLoading(true);
    // Simulate a delay or reload any necessary data
    await Future.delayed(Duration(seconds: 1));
    setLoading(false);
  }

  return Scaffold(
    appBar: AppBar(
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      backgroundColor: Colors.green[900],
      title: Text(
        "My Posts",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    body: RefreshIndicator(
      onRefresh: _refreshUserFeed, // Pull-to-refresh callback
      child: Container(
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
                .collection('posts')
                .where('userId', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final userPosts = snapshot.data!.docs;

              if (userPosts.isEmpty) {
                return buildNoPostsAvailableMessage();
              }

              userPosts.sort((a, b) {
                final timestampA =
                    (a.data() as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
                final timestampB =
                    (b.data() as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
                return (timestampB?.compareTo(timestampA ?? Timestamp.now()) ?? 0);
              });

              return CustomScrollView(
                slivers: [
                  // Add Post Card
                  SliverToBoxAdapter(
                    child: buildAddPostCard(
                      authProvider: authProvider,
                      context: context,
                      setLoading: setLoading,
                    ),
                  ),
                  // Loading Indicator
                  if (_isLoading)
                    SliverToBoxAdapter(
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.blue.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  // User Posts
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final postDoc = userPosts[index];
                        return buildPostList(
                          posts: [postDoc],
                          userCache: userCache,
                          context: context,
                          currentUserId: currentUserId,
                          setLoading: setLoading,
                        );
                      },
                      childCount: userPosts.length,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}




}


