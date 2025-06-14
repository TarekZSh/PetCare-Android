import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'dart:io';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/feed/video_player/video_post_widget.dart';
import 'package:logger/logger.dart';

class AddPostPage extends StatefulWidget {
  @override
  _AddPostPageState createState() => _AddPostPageState();
  final Function(bool) setLoading;
  final Map<String, dynamic>? postToEdit; 

  AddPostPage({required this.setLoading, this.postToEdit});
}

class _AddPostPageState extends State<AddPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _selectedMedia = []; // Each item will have {'file': File, 'isVideo': bool} 
  List<String> _deletedMedia = [];
  final logger = Logger();

@override
void initState() {
  super.initState();

  if (widget.postToEdit != null) {
    final post = widget.postToEdit!;
    _captionController.text = post['caption'] ?? '';

    if (post['media'] != null) {
      final mediaList = List<Map<String, dynamic>>.from(post['media']);
      setState(() {
        _selectedMedia = mediaList.map((media) {
          return {
            'file': null, // Files won't be loaded here; just URLs will be used for display.
            'url': media['url'],
            'isVideo': media['isVideo'] == 'true' , // Convert string to boolean
          };
        }).toList();
      });
    }
  }
}



  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }


Future<void> _addPost(AuthProvider authProvider) async {
  if (_captionController.text.isEmpty && _selectedMedia.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot post an empty post. Please add a caption or media."),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  widget.setLoading(true);
  Navigator.pop(context);

  try {
    String userId = authProvider.vet?.id ?? authProvider.petOwner?.id ?? '';
    String userRole = authProvider.vet != null ? "vet" : "pet_owner";

    // Media list to store uploaded URLs and their types
    List<Map<String, String>> mediaList = widget.postToEdit != null && widget.postToEdit!['media'] != null
        ? List<Map<String, dynamic>>.from(widget.postToEdit!['media']).map((media) {
            return {
              'url': media['url'].toString(),
              'isVideo': media['isVideo'].toString(), // Convert to string
            };
          }).toList()
        : [];

    logger.i('_selectedMedia: $_selectedMedia');

    // Remove deleted media URLs from the mediaList
    mediaList = mediaList.where((media) {
      return !_deletedMedia.contains(media['url']);
    }).toList();

    // Upload new media files
    for (var media in _selectedMedia) {
      if (media['file'] != null) { // New media
        try {
          final mediaUrl = await _uploadMediaToStorage(media['file'], media['isVideo']);
          mediaList.add({'url': mediaUrl, 'isVideo': media['isVideo'].toString()});
        } catch (e) {
          print("Failed to upload media: $e");
        }
      }
    }

    logger.e('len = ${mediaList.length}');

    // Create the post object
    final post = {
      'userId': userId,
      'userRole': userRole,
      'caption': _captionController.text.isEmpty ? null : _captionController.text,
      'media': mediaList, // Array of media objects
    };

    if (widget.postToEdit != null) {
      // Update the post
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postToEdit!['docId'])
          .update(post);
      print("Post updated successfully");
    } else {
      // Add a new post
      post['timestamp'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('posts').add(post);
      print("Post added successfully");
    }
  } catch (e) {
    print("Error adding/updating post: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save post. Please try again.")),
      );
    }
  } finally {
    widget.setLoading(false);
  }
}




Future<void> _pickMedia(bool isVideo) async {
  final picker = ImagePicker();
  try {
    final pickedFile = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && pickedFile.path.isNotEmpty) {
      setState(() {
        _selectedMedia.add({
          'file': File(pickedFile.path),
          'isVideo': isVideo,
        });
      });
    }
  } catch (e) {
    print("Error picking media: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to select media. Please try again.")),
    );
  }
}



Future<void> _captureMedia(bool isVideo) async {
  final picker = ImagePicker();
  XFile? pickedFile;

  try {
    pickedFile = isVideo
        ? await picker.pickVideo(source: ImageSource.camera)
        : await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null && pickedFile.path.isNotEmpty) {
      setState(() {
        _selectedMedia.add({
          'file': File(pickedFile!.path),
          'isVideo': isVideo,
        });
      });
    }
  } catch (e) {
    print("Error capturing media: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to capture media. Please try again.")),
    );
  }
}



Future<String> _uploadMediaToStorage(File media, bool isVideo) async {
 logger.e('media = $media, isVideo = $isVideo');
  try {
    final fileType = isVideo ? 'videos' : 'images';
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('post_$fileType')
        .child('${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}');

    final uploadTask = await storageRef.putFile(media);
    return await uploadTask.ref.getDownloadURL();
  } catch (e) {
    print('Error uploading media: $e');
    throw Exception("Failed to upload ${isVideo ? 'video' : 'image'}.");
  }
}


void _showMediaOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.green),
              title: Text("Capture Image"),
              onTap: () {
                Navigator.pop(context);
                _captureMedia(false);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo, color: Colors.green),
              title: Text("Pick Image"),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(false); 
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: Colors.blue),
              title: Text("Capture Video"),
              onTap: () {
                Navigator.pop(context);
                _captureMedia(true); 
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library, color: Colors.blue),
              title: Text("Pick Video"),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(true); 
              },
            ),
          ],
        ),
      );
    },
  );
}

AppBar _buildAppBar(AuthProvider authProvider) {
    return AppBar(
      centerTitle: true,
    title: Text(
      widget.postToEdit == null ? "Create Post" : "Edit Post",
      style: TextStyle(
        color: Colors.white, 
        fontSize: 20,       
        fontWeight: FontWeight.bold, 
      ),
    ),
      backgroundColor: Colors.green[900],
      elevation: 0,
      leading: IconButton(
      icon: Icon(Icons.close, color: Colors.white),
      onPressed: () {
        Navigator.pop(context);
      },
      ),
      actions: [
      TextButton(
        onPressed: _isSubmitting ? null : () => _addPost(authProvider),
        child: Text(
        widget.postToEdit == null ? "Post" : "Save", 
        style: TextStyle(fontSize: 16, color: Colors.white), 
        ),
      ),
      ],
    );
  }

Widget _buildAddPostForm(AuthProvider authProvider, String userName, String userProfilePictureUrl) {
  return SingleChildScrollView(
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: userProfilePictureUrl.isNotEmpty
                  ? NetworkImage(userProfilePictureUrl)
                  : authProvider.vet != null
                      ? AssetImage('assets/images/vetProfile.png') as ImageProvider
                      : AssetImage('assets/images/petOwnerProfile.png') as ImageProvider,
              radius: 25,
            ),
            SizedBox(width: 10),
            Text(
              userName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _captionController,
                decoration: InputDecoration(
                  hintText: authProvider.vet != null ? "What's on your mind?" : "Share a paw-some moment!",
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
              SizedBox(height: 10),
if (_selectedMedia.isNotEmpty)
  SizedBox(
    height: 250,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _selectedMedia.length,
      itemBuilder: (context, index) {
        final media = _selectedMedia[index];
        final file = media['file'] as File?;
        final isVideo = media['isVideo'];

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: file != null
                  ? isVideo
                      ? Container(
                          width: 250,
                          height: 250,
                          child: VideoPostWidget(videoUrl: file.path),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            file,
                            height: 250,
                            width: 250,
                            fit: BoxFit.cover,
                          ),
                        )
                  : media['url'] != null
                      ? isVideo
                          ? Container(
                              width: 250,
                              height: 250,
                              child: VideoPostWidget(videoUrl: media['url']),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                media['url'],
                                height: 250,
                                width: 250,
                                fit: BoxFit.cover,
                              ),
                            )
                      : Center(
                          child: Text(
                            isVideo ? "Video not available" : "Image not available",
                          ),
                        ),
            ),
            // Delete Button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    final media = _selectedMedia[index];
                    if (media['url'] != null) {
                      _deletedMedia.add(media['url']); // Track the deleted URL
                    }
                    _selectedMedia.removeAt(index); // Remove from the UI
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  ),




              IconButton(
                onPressed: () => _showMediaOptions(context),
                icon: Icon(Icons.perm_media, color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}




  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    String userName = authProvider.vet?.name ?? authProvider.petOwner?.name ?? '';
    String userProfilePictureUrl = authProvider.vet?.imageUrl ?? authProvider.petOwner?.imageUrl ?? '';

    return Scaffold(
      appBar:  _buildAppBar(authProvider),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildAddPostForm(authProvider, userName, userProfilePictureUrl),
      ),
    );
  }
}
