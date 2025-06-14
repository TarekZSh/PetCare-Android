import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pet_care_app/providers/app_state_notifier.dart';
import 'package:pet_care_app/screens/google_map_screen.dart';
import 'package:provider/provider.dart';

import '/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_care_app/common/app_theme.dart';
import 'package:pet_care_app/firebase/vet_class.dart';
import '/common/choice_chips_widget.dart';
import '/common/app_utils.dart';
import '/common/custom_widgets.dart';
import '/common/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'vet_profile_info_model.dart';
export 'vet_profile_info_model.dart';

class VetSignUpInfoWidget extends StatefulWidget {
  const VetSignUpInfoWidget(
      {super.key,
      required this.email,
      required this.password,
      this.isGoogleSignIn = false});

  final bool isGoogleSignIn;

  final String email;
  final String password;

  @override
  State<VetSignUpInfoWidget> createState() => _VetSignUpInfoWidgetState();
}

class _VetSignUpInfoWidgetState extends State<VetSignUpInfoWidget> {
  late VetSignUpInfoModel _model;
  File? _profileImage;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  void _submitForm() async {
    if (_validateInputs()) {
      try {
        String? licenseUrl;
        if (_model.licenseFile != null) {
          final storageRef = FirebaseStorage.instance.ref().child(
              'vet_licenses/${context.read<AuthProvider>().user?.uid}.pdf');

          final uploadTask = await storageRef.putFile(_model.licenseFile!);

          // Get the download URL
          licenseUrl = await uploadTask.ref.getDownloadURL();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? imageUrl;
        if (_profileImage != null) {
          // Generate a unique ID for the image
          final storageRef = FirebaseStorage.instance.ref().child(
              'vet_profiles/${context.read<AuthProvider>().user?.uid}.jpg');

          // Upload the file
          await storageRef.putFile(_profileImage!);

          // Get the download URL
          imageUrl = await storageRef.getDownloadURL();
        }
        if (!widget.isGoogleSignIn) {
          try {
            await authProvider.signUp(
              widget.email,
              widget.password,
              'vet',
            );
          } catch (error) {
            _handleSignUpError(error);
            return;
          }
        }
        // Create the vet object
        Vet vet = Vet(
          id: context.read<AuthProvider>().user?.uid ?? '',
          name: _model.nameController.text.trim(),
          bio: _model.bioController.text.trim(),
          email: _model.emailController.text.trim(),
          phone: _model.phoneController.text.trim(),
          location: _model.addressController.text.trim(),
          yearsOfExperience:
              double.tryParse(_model.experienceController.text.trim()) ?? 0.0,
          degree: _model.choiceChipsValue ?? '',
          university: _model.universityController.text.trim(),
          specializations: [],
          patients: [],
          imageUrl: imageUrl, // Add imageUrl to the Vet object
        );

        // Save to Firestore
        final success = await vet.saveToFirestore();
        authProvider.vet = vet;
        AppStateNotifier appStateNotifier =
            Provider.of<AppStateNotifier>(context, listen: false);
        appStateNotifier.saveDeviceToken(vet.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: success ? Colors.green : Colors.red,
              content: Text(success
                  ? 'Vet profile saved successfully!'
                  : 'Failed to save vet profile. Please try again.'),
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
              content: Text('Error: $e'),
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VetSignUpInfoModel());

    _model.nameController ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.bioController ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.emailController ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.phoneController ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();

    _model.addressController ??= TextEditingController();
    _model.textFieldFocusNode5 ??= FocusNode();

    _model.experienceController ??= TextEditingController();
    _model.textFieldFocusNode6 ??= FocusNode();

    _model.choiceChipsValueController ??= FormFieldController<List<String>>([]);

    _model.universityController ??= TextEditingController();
    _model.textFieldFocusNode7 ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
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
      padding: EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTextField(
              controller: _model.nameController!,
              focusNode: _model.textFieldFocusNode1!,
              label: 'Full Name *',
              icon: Icons.person,
              validator: _model.nameControllerValidator.asValidator(context),
            ),
            _buildTextField(
              controller: _model.bioController!,
              focusNode: _model.textFieldFocusNode2!,
              label: 'Bio',
              icon: Icons.description,
              maxLines: 3,
            ),
            _buildTextField(
              controller: _model.emailController!,
              focusNode: _model.textFieldFocusNode3!,
              label: 'Professional Email Address *',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: _model.emailControllerValidator.asValidator(context),
            ),
            _buildTextField(
              controller: _model.phoneController!,
              focusNode: _model.textFieldFocusNode4!,
              label: 'Phone Number *',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: _model.phoneControllerValidator.asValidator(context),
            ),
            _buildTextField(
              controller: _model.addressController!,
              focusNode: _model.textFieldFocusNode5!,
              label: 'Address *',
              icon: Icons.location_on,
              validator: _model.addressControllerValidator.asValidator(context),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GoogleMapScreen(
                      onPlaceSelected: (LatLng location, String address) {
                        Navigator.pop(context,
                            {'location': location, 'address': address});
                      },
                    ),
                  ),
                );

                if (result != null && result['address'] != null) {
                  _model.addressController!.text = result['address'];
                }
              },
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _model.universityController!,
              focusNode: _model.textFieldFocusNode7!,
              label: 'University *',
              icon: Icons.school,
              validator:
                  _model.universityControllerValidator.asValidator(context),
            ),
            _buildDegreeChips(),
            const SizedBox(height: 8),
            _buildExperienceField(),
            const SizedBox(height: 8),
            _buildLiecenceField(),
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
    required FocusNode focusNode,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
    VoidCallback? onTap, // Added onTap parameter
// Added readOnly parameter for fields like address
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onTap: onTap, // Attach onTap callback
        readOnly: onTap != null, // Make field read-only if required
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

  bool _validateInputs() {
    if (_model.nameController.text.trim().isEmpty) {
      _showErrorSnackbar('Full Name is required.');
      return false;
    }

    if (_model.emailController.text.trim().isEmpty) {
      _showErrorSnackbar('Email Address is required.');
      return false;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(_model.emailController.text.trim())) {
      _showErrorSnackbar('Enter a valid Email Address.');
      return false;
    }

    if (_model.phoneController.text.trim().isEmpty ||
        !RegExp(r'^05\d{8}$').hasMatch(_model.phoneController.text.trim())) {
      _showErrorSnackbar('Enter a valid Phone Number.');
      return false;
    }

    if (_model.addressController.text.trim().isEmpty) {
      _showErrorSnackbar('Address is required.');
      return false;
    }

    if (_model.experienceController.text.trim().isEmpty ||
        !RegExp(r'^\d{1,2}$')
            .hasMatch(_model.experienceController.text.trim())) {
      _showErrorSnackbar('Experience Years must be a maximum of two digits.');
      return false;
    }
    if (_model.universityController.text.trim().isEmpty) {
      _showErrorSnackbar('University is required.');
      return false;
    }

    return true;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildExperienceField() {
    return _buildTextField(
      controller: _model.experienceController!,
      focusNode: _model.textFieldFocusNode6!,
      label: 'Experience Years *',
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildLiecenceField() {
    return GestureDetector(
      onTap: _model.licenseFile == null
          ? () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'doc', 'docx'], // Allowed file types
              );
              if (result != null && result.files.single.path != null) {
                setState(() {
                  _model.licenseFile =
                      File(result.files.single.path!); // Save file in model
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Document selected: ${result.files.single.name}'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No document selected.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          : null, // Disable file picker if a file is already selected
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: appTheme.of(context).primary, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              color: appTheme.of(context).primary,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              'License Verification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _model.licenseFile != null
                  ? 'Document Selected: ${_model.licenseFile!.path.split('/').last}'
                  : 'Tap to upload a veterinary license document',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            if (_model.licenseFile != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: appTheme.of(context).primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'File is ready to upload',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: appTheme.of(context).primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _model.licenseFile = null; // Remove the file
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Document removed successfully.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDegreeChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Degree *', style: appTheme.of(context).bodyMedium),
          const SizedBox(height: 16),
          appChoiceChips(
            controller: _model.choiceChipsValueController!,
            chipSpacing: 8.0,
            multiselect: false,
            options: [
              ChipData("Bachelor"),
              ChipData("Master"),
              ChipData('Doctor'),
              ChipData('PhD')
            ],
            onChanged: (val) =>
                safeSetState(() => _model.choiceChipsValue = val?.firstOrNull),
            selectedChipStyle: ChipStyle(
              backgroundColor: appTheme.of(context).success,
              textStyle: TextStyle(color: Colors.white),
            ),
            unselectedChipStyle: ChipStyle(
              backgroundColor: const Color(0xFFF5F5F5),
              textStyle: appTheme.of(context).bodySmall,
            ),
          ),
        ],
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
                  barrierDismissible: false, // Prevent dismissing the dialog
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
                    // Navigate to the desired route
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
}
