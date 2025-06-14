import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


////////////////////////////show likes///////////////////////
Future<List<Map<String, dynamic>>> fetchLikes({
  required List<dynamic> likedBy,
}) async {
  List<Map<String, dynamic>> users = [];

  for (String userId in likedBy) {
    try {
      DocumentSnapshot vetDoc =
          await FirebaseFirestore.instance.collection('vets').doc(userId).get();

      if (vetDoc.exists) {
        users.add({
          ...vetDoc.data() as Map<String, dynamic>,
          'role': 'vet', 
        });
        continue;
      }

      DocumentSnapshot ownerDoc = await FirebaseFirestore.instance
          .collection('pet_owners')
          .doc(userId)
          .get();

      if (ownerDoc.exists) {
        users.add({
          ...ownerDoc.data() as Map<String, dynamic>,
          'role': 'pet_owner', 
        });
        continue;
      }

      users.add({
        'name': 'Unknown User',
        'imageUrl': '',
        'role': 'unknown', 
      });
    } catch (e) {
      print("Error fetching user data: $e");
      users.add({
        'name': 'Unknown User',
        'imageUrl': '',
        'role': 'unknown', 
      });
    }
  }
  return users;
}

void showNoLikesModal({
  required BuildContext context,
}) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              "Likes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16.0),
            // No Likes Content
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/no_likes.png', // Replace with your asset path
                        height: 150,
                        width: 150,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No Likes Yet!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "This post doesn't have any likes yet",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}




void showLikesModal({
  required BuildContext context,
  required List<dynamic> likedBy,
}) async {
  List<Map<String, dynamic>> users = await fetchLikes(likedBy: likedBy);

  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Likes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Colors.grey[300]),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['imageUrl'] != null &&
                              user['imageUrl'].isNotEmpty
                          ? NetworkImage(user['imageUrl'])
                          : user['profileImageUrl'] != null &&
                                  user['profileImageUrl'].isNotEmpty
                              ? NetworkImage(user['profileImageUrl'])
                              : user['role'] == 'vet'
                                  ? AssetImage('assets/images/vetProfile.png')
                                      as ImageProvider
                                  : AssetImage(
                                          'assets/images/petOwnerProfile.png')
                                      as ImageProvider,
                    ),
                    title: Text(user['name'] ?? 'Unknown User'),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
