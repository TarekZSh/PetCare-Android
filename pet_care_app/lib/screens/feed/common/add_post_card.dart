import 'package:flutter/material.dart';
import 'package:pet_care_app/screens/feed/add_post_page.dart';
import 'package:pet_care_app/providers/auth_provider.dart';

Widget buildAddPostCard({
  required AuthProvider authProvider,
  required BuildContext context,
  required Function(bool) setLoading,
}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AddPostPage(postToEdit: null, setLoading: setLoading),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Card(
        color: Colors.grey[290],
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: authProvider.vet?.imageUrl != null &&
                        authProvider.vet!.imageUrl!.isNotEmpty
                    ? NetworkImage(authProvider.vet!.imageUrl!)
                    : authProvider.petOwner?.imageUrl != null &&
                            authProvider.petOwner!.imageUrl!.isNotEmpty
                        ? NetworkImage(authProvider.petOwner!.imageUrl!)
                        : authProvider.vet != null
                            ? AssetImage('assets/images/vetProfile.png')
                                as ImageProvider
                            : AssetImage('assets/images/petOwnerProfile.png')
                                as ImageProvider,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  authProvider.vet != null
                      ? "What's on your mind?"
                      : "Share a paw-some moment!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}