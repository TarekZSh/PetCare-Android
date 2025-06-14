import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/chat/chat_list.dart';
import 'package:pet_care_app/screens/pet_owner/pet_owner_profile_widget.dart';
import 'package:pet_care_app/screens/pets_and_vets_lists/vets_and_pets_lists_widget.dart';
import 'package:pet_care_app/screens/vet/vet_profile.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/screens/feed/global_feed.dart';
// Make sure to import your AuthProvider here

class MainScreenManager extends StatefulWidget {
  const MainScreenManager({Key? key}) : super(key: key);

  @override
  State<MainScreenManager> createState() => MainScreenManagerState();
}

class MainScreenManagerState extends State<MainScreenManager> {
  int _selectedIndex = 0;
  bool _hasUnreadMessages = false;

  @override
  void initState() {
    super.initState();
    _listenForUnreadMessages();
  }


late StreamSubscription<QuerySnapshot> _chatListener;

void _listenForUnreadMessages() {
  final userId = Provider.of<AuthProvider>(context, listen: false).petOwner?.id ??
      Provider.of<AuthProvider>(context, listen: false).vet?.id;

  if (userId != null) {
    // Listen to changes in the Chats collection
    _chatListener = FirebaseFirestore.instance
        .collection('Chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      try {
        // Filter documents to check 'unreadCount' for the current user
        bool hasUnread = snapshot.docs.any((doc) {
          final data = doc.data();

          // Safely check if the 'unreadCount' field exists and is valid
          if (data.containsKey('unreadCount')) {
            final unreadCount = data['unreadCount'];
            if (unreadCount is Map<String, dynamic>) {
              final userUnreadCount = unreadCount[userId];
              return userUnreadCount != null && userUnreadCount > 0;
            }
          }

          return false;
        });

        // Update state only if there is a change in unread message status
        if (mounted && _hasUnreadMessages != hasUnread) {
          setState(() {
            _hasUnreadMessages = hasUnread;
          });
        }
      } catch (e) {
        print('Error processing Firestore snapshot: $e');
      }
    });
  }
}

@override
void dispose() {
  // Cancel the Firestore listener to prevent memory leaks
  _chatListener.cancel();
  super.dispose();
}


  /// Fetches screens dynamically based on the user type
  List<Widget> _getScreens(AuthProvider authProvider) {
    Widget profilePage;

    if (authProvider.vet != null) {
      profilePage = VetProfileWidget();
    } else if (authProvider.petOwner != null) {
      profilePage = PetOwnerPetListWidget();
    } else {
      profilePage = VetsandpetslistsWidget();
    }

    return [
      profilePage,
      VetsandpetslistsWidget(),
      ChatListScreen(),
      GlobalFeed(),
    ];
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screens = _getScreens(authProvider);

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (_hasUnreadMessages)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed),
            label: 'Feed',
          ),
        ],
      ),
    );
  }
}



class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coming Soon'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.construction,
              size: 100,
              color: Colors.orange,
            ),
            SizedBox(height: 20),
            Text(
              'This feature is under development.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Please check back later!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
