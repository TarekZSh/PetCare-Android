import 'package:flutter/material.dart';

class PetOwnerSignUpModel {
  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController birthDayController;
  late TextEditingController locationController;

  FocusNode? textFieldFocusNode1;
  FocusNode? textFieldFocusNode2;
  FocusNode? textFieldFocusNode3;
  FocusNode? textFieldFocusNode4;

  PetOwnerSignUpModel() {
    nameController = TextEditingController();
    bioController = TextEditingController();
    birthDayController = TextEditingController();
    locationController = TextEditingController();

    textFieldFocusNode1 = FocusNode();
    textFieldFocusNode2 = FocusNode();
    textFieldFocusNode3 = FocusNode();
    textFieldFocusNode4 = FocusNode();
  }

  void dispose() {
    nameController.dispose();
    bioController.dispose();
    birthDayController.dispose();
    locationController.dispose();
    textFieldFocusNode1?.dispose();
    textFieldFocusNode2?.dispose();
    textFieldFocusNode3?.dispose();
    textFieldFocusNode4?.dispose();
  }

  // Validators for the text fields
  String? Function(BuildContext, String?) get nameControllerValidator =>
      (context, value) {
        if (value == null || value.trim().isEmpty) {
          return 'Full Name is required';
        }
        return null;
      };

  String? Function(BuildContext, String?) get bioControllerValidator =>
      (context, value) {
        if (value != null && value.length > 200) {
          return 'Bio should not exceed 200 characters';
        }
        return null;
      };

  String? Function(BuildContext, String?) get birthDayControllerValidator =>
      (context, value) {
        if (value != null && !RegExp(r'^\d{4}-\d{2}-\d{2}\$').hasMatch(value)) {
          return 'Enter a valid date (YYYY-MM-DD)';
        }
        return null;
      };

  String? Function(BuildContext, String?) get locationControllerValidator =>
      (context, value) {
        if (value == null || value.trim().isEmpty) {
          return 'Location is required';
        }
        return null;
      };
}
