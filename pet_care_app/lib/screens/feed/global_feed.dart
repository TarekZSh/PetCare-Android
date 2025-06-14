import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/feed/common/common_func.dart';
import 'package:pet_care_app/screens/feed/user_feed.dart';


class GlobalFeed extends StatefulWidget {
  @override
  _GlobalFeedState createState() => _GlobalFeedState();
}

class _GlobalFeedState extends State<GlobalFeed> {
  Map<String, Map<String, dynamic>> userCache = {};

  bool _isLoading = false; 
  void setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }


AppBar _buildAppBar(String currentUserId) {
  return AppBar(
    backgroundColor: Colors.green[900],
    elevation: 0.5,
    title: Text(
      'Paw-some Feed',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    actions: [
      buildNotificationsIcon(currentUserId,userCache), // Use the separated function
      IconButton(
        icon: Icon(
          Icons.person_outline,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserFeed(),
            ),
          );
        },
      ),
    ],
  );
}



@override
Widget build(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context);

  final currentUserId = authProvider.petOwner != null
      ? authProvider.petOwner!.id
      : authProvider.vet!.id;

  Future<void> _refreshFeed() async {
    setLoading(true);
    // Simulate a delay or reload any necessary data
    await Future.delayed(Duration(seconds: 1));
    setLoading(false);
  }

  return Scaffold(
    appBar: _buildAppBar(currentUserId),
    body: RefreshIndicator(
      onRefresh: _refreshFeed, // Pull-to-refresh callback
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
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data!.docs;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: buildAddPostCard(
                      authProvider: authProvider,
                      context: context,
                      setLoading: setLoading,
                    ),
                  ),
                  if (_isLoading)
                    SliverToBoxAdapter(
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.blue.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  if (posts.isEmpty)
                    SliverToBoxAdapter(
                      child: buildNoPostsAvailableMessage(),
                    )
                  else
                    SliverToBoxAdapter(
                      child: buildPostList(
                        posts: posts,
                        userCache: userCache,
                        context: context,
                        currentUserId: currentUserId,
                        setLoading: setLoading,
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