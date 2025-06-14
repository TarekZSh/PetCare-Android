import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care_app/screens/feed/post_detail_page.dart';
import 'package:pet_care_app/screens/feed/add_post_page.dart';

//////////////////////edit and delete posts/////////////
Future<void> handleEditPost({
  required BuildContext context,
  required Map<String, dynamic> post,
  required Function(bool) setLoading,
}) async {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddPostPage(
        postToEdit: post, 
        setLoading: setLoading,
      ),
    ),
  );
}

Future<void> handleDeletePost({
  required BuildContext context,
  required String postId,
}) async {
  final rootContext = context;
  
  bool? confirmDelete = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Delete Post"),
        content: Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), 
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), 
            child: Text("Delete"),
          ),
        ],
      );
    },
  );

  if (confirmDelete == true) {
    try {
      // Start Firestore batch write
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Delete the post
      DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
      batch.delete(postRef);

      // Query notifications linked to this post
      QuerySnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('postId', isEqualTo: postId)
          .get();

      // Add each notification to the batch for deletion
      for (var doc in notificationSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit batch write (deletes post + notifications together)
      await batch.commit();

      logger.i('Post and related notifications deleted successfully: $postId');
      
      // Show success message
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text("Post deleted successfully.")),
      );
    } catch (e) {
      logger.e('Error deleting post or notifications: $e');
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text("Failed to delete post. Please try again.")),
      );
    }
  }
}
