import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pet_care_app/providers/app_state_notifier.dart';
import '/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_care_app/common/app_theme.dart';
import 'package:pet_care_app/firebase/pet_owner_class.dart';
import 'package:provider/provider.dart';
import '/common/custom_widgets.dart';

class PetOwnerSignUpInfoWidget extends StatefulWidget {
  const PetOwnerSignUpInfoWidget(
      {super.key,
      required this.email,
      required this.password,
      this.isGoogleSignIn = false});
  final bool isGoogleSignIn;

  final String email;
  final String password;

  @override
  State<PetOwnerSignUpInfoWidget> createState() =>
      _PetOwnerSignUpInfoWidgetState();
}

class _PetOwnerSignUpInfoWidgetState extends State<PetOwnerSignUpInfoWidget> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _birthDayController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  File? _profileImage;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _birthDayController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_validateInputs()) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? imageUrl;
        if (_profileImage != null) {
          // Generate a unique ID for the image
          final storageRef = FirebaseStorage.instance.ref().child(
              'pet_owner_profiles/${context.read<AuthProvider>().user?.uid}.jpg');

          // Upload the file
          await storageRef.putFile(_profileImage!);

          // Get the download URL
          imageUrl = await storageRef.getDownloadURL();
        }

        if (!widget.isGoogleSignIn) {
          try {
            await authProvider.signUp(
                widget.email, widget.password, 'pet_owner');
          } catch (error) {
            _handleSignUpError(error);
            return;
          }
        }

        // Create the PetOwner object
        final petOwner = PetOwner(
          id: context.read<AuthProvider>().user?.uid ?? '',
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          birthDay: _birthDayController.text.trim(),
          imageUrl: imageUrl, // Save the image URL
          pets: [],
        );

        // Save to Firestore
        final success = await petOwner.saveToFirestore();

        authProvider.petOwner = petOwner;
        AppStateNotifier appStateNotifier =
            Provider.of<AppStateNotifier>(context, listen: false);
        appStateNotifier.saveDeviceToken(petOwner.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Profile saved successfully!'
                    : 'Failed to save profile.',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) {
            context.go('/main-screen');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleSignUpError(dynamic error) {
    context.pop();
    String errorMessage;
    if (error.toString().contains('email-already-in-use')) {
      errorMessage =
          'Email already in use. Please use a different email or sign in.';
    } else if (error.toString().contains('weak-password')) {
      errorMessage = 'Password is too weak. Please use a stronger password.';
    } else if (error.toString().contains('invalid-email')) {
      errorMessage = 'Invalid email. Please enter a valid email address.';
    } else {
      errorMessage = 'Failed to sign up. Please try again.';
    }
    _showSnackBar(errorMessage, appTheme.of(context).error);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: appTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: Colors.white,
              ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(16.0),
      ),
    );
  }

  void _cancelRegistration() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Registration'),
          content: const Text(
              'Are you sure you want to cancel registration? You will need to reregister if you proceed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                // Show a loading indicator
                showDialog(
                  context: context,
                  barrierDismissible:
                      false, // Prevent dismissing the dialog manually
                  builder: (BuildContext context) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );

                try {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  await auth.deleteAccount(); // Perform account deletion

                  if (mounted) {
                    // Close the loading dialog and navigate to the login route
                    Navigator.of(context).pop(); // Close the loading dialog
                    context.go('/login'); // Use the correct route
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop(); // Close the loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Error during account deletion: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  bool _validateInputs() {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackbar('Full Name is required.');
      return false;
    }
    if (_phoneNumberController.text.trim().isEmpty ||
        !RegExp(r'^05\d{8}$').hasMatch(_phoneNumberController.text.trim())) {
      _showErrorSnackbar('Enter a valid Phone Number.');
      return false;
    }
    return true;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: appTheme.of(context).primaryBackground,
        body: Stack(
          children: [
            _buildGradientBackground(),
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildInputSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.blue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Container(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          decoration: const BoxDecoration(
            color: Color(0x66000000), // Semi-transparent overlay
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 280,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage:
                  _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null
                  ? Icon(Icons.add_a_photo, color: Colors.white, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Complete Your Profile',
            textAlign: TextAlign.center,
            style: appTheme.of(context).headlineSmall.override(
                  fontFamily: 'Inter Tight',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us personalize your experience',
            textAlign: TextAlign.center,
            style: appTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Full Name *',
              icon: Icons.person,
            ),
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              icon: Icons.description,
              maxLines: 3,
            ),
            _buildTextField(
              controller: _phoneNumberController,
              label: 'Phone Number *',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _birthDayController,
              label: 'Birth Day',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.none, // Disable manual typing
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  helpText: 'Select your Birth Day',
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900), // Earliest selectable date
                  lastDate: DateTime.now(), // Latest selectable date
                );
                if (pickedDate != null) {
                  _birthDayController.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 16),
            _buildSubmitButton(),
            const SizedBox(height: 16),
            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap, // Add onTap parameter
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onTap: onTap, // Use onTap to open calendar
        readOnly: onTap != null, // Make field read-only if onTap is provided
        decoration: InputDecoration(
          labelText: label,
          labelStyle: appTheme.of(context).bodyMedium,
          prefixIcon: icon != null
              ? Icon(icon, color: appTheme.of(context).primary)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: appTheme.of(context).primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: appTheme.of(context).primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: appTheme.of(context).primary),
          ),
          filled: true,
          fillColor: appTheme.of(context).secondaryBackground,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ButtonWidget(
      onPressed: _submitForm,
      text: 'Complete Setup',
      options: ButtonOptions(
        width: double.infinity,
        height: 50,
        color: appTheme.of(context).success,
        textStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        borderRadius: BorderRadius.circular(25),
        elevation: 5,
      ),
    );
  }

  Widget _buildCancelButton() {
    return ButtonWidget(
      onPressed: _cancelRegistration,
      text: 'Cancel Registration',
      options: ButtonOptions(
        width: double.infinity,
        height: 50,
        color: Colors.red,
        textStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        borderRadius: BorderRadius.circular(25),
        elevation: 5,
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              if (_profileImage !=
                  null) // Show delete option if image is picked
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete Image'),
                  textColor: Colors.red,
                  onTap: () {
                    _deletePickedImage();
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _deletePickedImage() {
    setState(() {
      _profileImage = null; // Clear the picked image
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
}
