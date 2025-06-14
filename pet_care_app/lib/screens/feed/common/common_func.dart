import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

export 'add_post_card.dart';
export 'build_posts_list.dart';
export 'edit_delete_post.dart';
export 'like_unlike_post.dart';
export 'show_likes.dart';
export 'notification_icon.dart';

Future<void> fetchUserData(
    String userId, Map<String, Map<String, dynamic>> userCache) async {
  if (!userCache.containsKey(userId)) {
    try {
      var userDoc =
          await FirebaseFirestore.instance.collection('vets').doc(userId).get();
      if (userDoc.exists) {
        userCache[userId] = {
          ...userDoc.data() as Map<String, dynamic>,
          'role': 'vet', // Add role information
        };
        return;
      }

      userDoc = await FirebaseFirestore.instance
          .collection('pet_owners')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        userCache[userId] = {
          ...userDoc.data() as Map<String, dynamic>,
          'role': 'pet_owner', // Add role information
        };
      } else {
        userCache[userId] = {
          'name': 'Unknown User',
          'imageUrl': '',
          'role': 'unknown', // Default role for unknown users
        };
      }
    } catch (e) {
      userCache[userId] = {
        'name': 'Unknown User',
        'imageUrl': '',
        'role': 'unknown', // Default role for error cases
      };
    }
  }
}




