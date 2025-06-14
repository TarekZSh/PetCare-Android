import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_care_app/common/icon_button_widget.dart';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '/common/app_theme.dart';
import '/common/app_utils.dart';
import '/common/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'add_pet_model.dart';
export 'add_pet_model.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AddPetWidget extends StatefulWidget {
  const AddPetWidget({super.key});

  @override
  State<AddPetWidget> createState() => _AddPetWidgetState();
}

class _AddPetWidgetState extends State<AddPetWidget> {
  late AddPetModel _model;
  File? _profileImage;
  TextEditingController? bioController;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddPetModel());

    _model.petNameController ??= TextEditingController();
    _model.speciesController ??= TextEditingController();
    _model.genderController ??= TextEditingController();
    _model.breedController ??= TextEditingController();
    _model.ageController ??= TextEditingController();
    _model.weightController ??= TextEditingController();
    _model.heightController ??= TextEditingController();
    bioController = TextEditingController();
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

  Widget _buildProfileImageSection(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: appTheme.of(context).success,
                width: 2,
              ),
              image: _profileImage != null
                  ? DecorationImage(
                      image: FileImage(_profileImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _profileImage == null
                ? const Icon(Icons.add_a_photo, size: 60, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        ButtonWidget(
          onPressed: _showImagePickerOptions,
          text: 'Upload Photo',
          options: ButtonOptions(
            width: 160,
            height: 40,
            color: appTheme.of(context).success,
            textStyle: appTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  Future<void> _savePetInfo() async {
    try {
      // Generate a unique ID for the pet
      final String petId = const Uuid().v4();

      // Check if a profile image is selected
      String? imageUrl;
      if (_profileImage != null) {
        print('Uploading image...');
        // Create a reference to Firebase Storage
        final storageRef =
            FirebaseStorage.instance.ref().child('pet_profiles/$petId.jpg');

        // Upload the file
        await storageRef.putFile(_profileImage!);

        // Get the download URL
        imageUrl = await storageRef.getDownloadURL();
        print('Image uploaded successfully: $imageUrl');
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Create the pet object with the image URL
      final pet = Pet(
        id: petId,
        ownerId: authProvider.petOwner!.id,
        name: _model.petNameController?.text ?? '',
        species: _model.speciesController?.text ?? '',
        gender: _model.genderController?.text ?? '',
        breed: _model.breedController?.text ?? '',
        weight: double.tryParse(_model.weightController?.text ?? '0') ?? 0,
        height: double.tryParse(_model.heightController?.text ?? '0') ?? 0,
        age: double.tryParse(_model.ageController?.text ?? '0') ?? 0,
        owner: authProvider.petOwner!.name,
        bio: bioController?.text ?? '',
        birthDate: _birthDate,
        imageUrl: imageUrl, // Add the image URL here
        specialNotes: [],
        lastActivities: [],
        medicalHistory: [],
        vaccinations: [],
        events: [],
        vetEvents: [],
        documents: [],
      );

      // Save the pet object to Firestore
      final bool success = await pet.saveToFirestore();

      if (authProvider.petOwner != null) {
        // Add the pet to the pet owner's list
        authProvider.petOwner!.pets.add(pet);

        // Save the updated pet owner to Firestore
        await authProvider.petOwner!.saveToFirestore().then((_) {
          // Notify listeners after saving
          authProvider.notifyListeners();
          print('Pet added and UI updated.');
        }).catchError((e) {
          print('Failed to save pet owner: $e');
        });
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _model.clearFields();
        context.go('/main-screen');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save pet profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Select birth date and calculate age
  void _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: "Select your pet birthday", // Add help text
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        double age = _calculateAge(picked);
        _model.ageController?.text = age.toStringAsFixed(1); // Update age field
      });
    }
  }

  /// Calculate age from birth date
  double _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int years = today.year - birthDate.year;
    int months = today.month - birthDate.month;

    if (months < 0 || (months == 0 && today.day < birthDate.day)) {
      years--;
      months += 12;
    }

    return years + (months / 12); // Return age as a decimal
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
            _buildContent(context),
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

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Bar Section
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                appIconButton(
                  borderRadius: 20.0,
                  buttonSize: 48.0,
                  fillColor: Color(0x33FFFFFF),
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24.0,
                  ),
                  onPressed: () {
                    context.pop();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Title Section
          Text(
            'Create Pet Profile',
            style: appTheme.of(context).displaySmall.override(
                  fontFamily: 'Inter Tight',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your furry friend',
            style: appTheme.of(context).bodyLarge.override(
                  fontFamily: 'Inter',
                  color: const Color(0xFFE0E0E0),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Pet Details and Health Overview with Elevation
          Material(
            elevation: 4, // Elevation effect
            borderRadius: BorderRadius.circular(16), // Rounded corners
            child: _buildSectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileImageSection(context),
                  const SizedBox(height: 16),
                  _buildPetDetailsSection(),
                  const SizedBox(height: 24),
                  _buildHealthOverviewSection(),
                  const SizedBox(height: 24),
                  _buildButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            title,
            style: appTheme.of(context).headlineSmall.override(
                  fontFamily: 'Inter Tight',
                  color: appTheme.of(context).primaryText,
                ),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 12), // Adjust padding
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: appTheme.of(context).success),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style:
            const TextStyle(fontSize: 16, height: 1.5), // Increase line height
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: appTheme.of(context).success),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: (value) {
          controller.text = value ?? '';
        },
      ),
    );
  }

  Widget _buildPetDetailsSection() {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField('Pet Name *', _model.petNameController!),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextFormField(
                controller: bioController!,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Type your bio here',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appTheme.of(context).success),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLength: 75,
                maxLines: 3,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    'Species *',
                    [
                      'Unknown',
                      'Dog',
                      'Cat',
                      'Bird',
                      'Fish',
                      'Hamster',
                      'Rabbit',
                      'Turtle',
                      'Snake',
                      'Lizard',
                      'Frog',
                      'Horse',
                      'Pig',
                      'Goat',
                      'Sheep',
                      'Chicken',
                      'Duck',
                      'Goose',
                      'Parrot',
                      'Ferret',
                      'Guinea Pig',
                      'Chinchilla',
                      'Hedgehog',
                      'Tarantula',
                      'Scorpion'
                    ],
                    _model.speciesController!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    'Gender *',
                    ['Male', 'Female', 'Other'],
                    _model.genderController!,
                  ),
                ),
              ],
            ),
            _buildTextField('Breed *', _model.breedController!),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthOverviewSection() {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildCard(
          title: 'Health Overview',
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    '* Weight (kg)',
                    _model.weightController!,
                    inputType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,2}(\.\d{0,1})?$')),
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    '* Height (cm)',
                    _model.heightController!,
                    inputType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,2}(\.\d{0,1})?$')),
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectBirthDate(context),
                    child: AbsorbPointer(
                      child: _buildTextField(
                        '* Age (years)',
                        _model.ageController!,
                        inputType: TextInputType.number,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ButtonWidget(
          onPressed: () {
            _model.clearFields();
          },
          text: 'Reset',
          options: ButtonOptions(
            width: 150,
            height: 50,
            color: const Color(0xFFF5F5F5),
            textStyle: appTheme.of(context).titleSmall.override(
                  fontFamily: 'Inter Tight',
                  color: appTheme.of(context).secondaryText,
                ),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        ButtonWidget(
          onPressed: () async {
            if (_model.petNameController.text.isEmpty ||
                _model.speciesController.text.isEmpty ||
                _model.genderController.text.isEmpty ||
                _model.breedController.text.isEmpty ||
                _model.ageController.text.isEmpty ||
                _model.weightController.text.isEmpty ||
                _model.heightController.text.isEmpty) {
              final snackBar = SnackBar(
                content: Text("Please fill all required fields!"),
                backgroundColor: Colors.red,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            } else {
              await _savePetInfo();
            }
          },
          text: 'Save Profile',
          options: ButtonOptions(
            width: 150,
            height: 50,
            color: appTheme.of(context).success,
            textStyle: appTheme.of(context).titleSmall.override(
                  fontFamily: 'Inter Tight',
                  color: Colors.white,
                ),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ],
    );
  }
}
