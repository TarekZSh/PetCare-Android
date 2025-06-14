import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

Future<void> pickImage(BuildContext context, ImageSource source,
    {Function(File)? onImagePicked}) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    final imageFile = File(pickedFile.path);
    if (onImagePicked != null) {
      onImagePicked(imageFile);
    }
  }
}

void deleteImage(BuildContext context,
    {Function()? onImageDeleted,
    required StateSetter setState,
    required String tybe}) {
  // This ensures the UI rebuilds
  setState(() {
    if (onImageDeleted != null) {
      onImageDeleted();
    }
  });
}

void showImagePickerOptions(BuildContext context,
    {Function(File)? onImagePicked,
    Function()? onImageDeleted,
    File? profileImage,
    String? imageUrl,
    required StateSetter setState,
    required String tybe}) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                pickImage(context, ImageSource.gallery,
                    onImagePicked: onImagePicked);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Take a Photo'),
              onTap: () {
                pickImage(context, ImageSource.camera,
                    onImagePicked: onImagePicked);
                Navigator.of(context).pop();
              },
            ),
            if (profileImage != null ||
                imageUrl != null) // Only show delete option if there's an image
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title:
                    Text('Delete Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  deleteImage(context, onImageDeleted: () {
                    setState(() {
                      profileImage = null;
                      imageUrl = null;
                    });
                    if (onImageDeleted != null) {
                      onImageDeleted();
                    }
                  }, setState: setState, tybe: tybe);
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<bool> showEditProfileDialog(
  BuildContext context,
  TextEditingController nameController,
  TextEditingController bioController,
  String? profileImageUrl,
  String oldName,
  String oldBio,
  Function(File?, String?) onImagePicked,
  Function() onImageDeleted, {
  String tybe = 'pet',
}) {
  Logger logger = Logger();
  final _formKey = GlobalKey<FormState>();
  File? _tempProfileImage;
  String? _tempProfileImageUrl = profileImageUrl;
  bool isSaving = false;

  final completer = Completer<bool>();

showDialog(
  context: context,
  builder: (BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AlertDialog(
          title: Text('Edit Details'),
          content: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showImagePickerOptions(
                          context,
                          onImagePicked: (imageFile) {
                            setState(() {
                              _tempProfileImage = imageFile;
                              _tempProfileImageUrl = null;
                            });
                          },
                          onImageDeleted: () {
                            setState(() {
                              _tempProfileImage = null;
                              _tempProfileImageUrl = '';
                            });
                          },
                          profileImage: _tempProfileImage,
                          imageUrl: _tempProfileImageUrl,
                          setState: setState,
                          tybe: tybe,
                        );
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _tempProfileImage != null
                                ? FileImage(_tempProfileImage!)
                                : (_tempProfileImageUrl != null && _tempProfileImageUrl!.isNotEmpty)
                                    ? NetworkImage(_tempProfileImageUrl!)
                                    : AssetImage(
                                        tybe == 'doctor'
                                            ? 'assets/images/vetProfile.png'
                                            : tybe == 'pet'
                                                ? 'assets/images/PetProfilePicture.png'
                                                : 'assets/images/petOwnerProfile.png',
                                      ) as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 30.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: tybe == 'pet' ? 'Enter your pet\'s name' : 'Enter your name',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 40,
                        maxLines: null, // Allows the TextField to grow dynamically
                    minLines: 1,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: bioController,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        hintText: tybe == 'pet' ? 'Enter your pet\'s bio' : 'Enter your bio',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 75,
                        maxLines: null, // Allows the TextField to grow dynamically
                    minLines: 1,
                    inputFormatters: [
    FilteringTextInputFormatter.singleLineFormatter, // Prevents new lines
  ],
                    ),
                    if (isSaving) ...[
                      SizedBox(height: 16),
                      CircularProgressIndicator(), // Show loading indicator during save
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.text = oldName;
                bioController.text = oldBio;
                Navigator.of(context).pop();
                completer.complete(false); // Return false on cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    isSaving = true;
                  });

                  String newImageUrl = profileImageUrl ?? '';
                  logger.d('newImageUrl: $newImageUrl');
                  try {
                    logger.d('Uploading image');
                    if (_tempProfileImage != null) {
                      logger.d('tempProfileImage is not null');
                      final storageRef = FirebaseStorage.instance
                          .ref()
                          .child(tybe == 'pet_profiles' ? 'pet_owner_profiles' : 'vet_profiles')
                          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
                      await storageRef.putFile(_tempProfileImage!);
                      newImageUrl = await storageRef.getDownloadURL();
                      onImagePicked(_tempProfileImage, newImageUrl);
                    } else if (_tempProfileImageUrl == '') {
                      logger.d('tempProfileImageUrl is null');
                      onImageDeleted();
                    } else {
                      logger.d('tarek');
                      onImagePicked(_tempProfileImage, newImageUrl);
                    }
                  } catch (e) {
                    logger.d('Error during upload: $e');
                  } finally {
                    logger.d('Saving profile details');
                    setState(() {
                      isSaving = false;
                    });

                    Navigator.of(context).pop();
                    completer.complete(true); // Return true on save
                  }
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  },
);

  return completer.future;
}
