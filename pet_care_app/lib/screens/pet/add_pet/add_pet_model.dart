import '/common/app_utils.dart';
import 'add_pet.dart' show AddPetWidget;
import 'package:flutter/material.dart';

class AddPetModel extends BaseModel<AddPetWidget> {
  /// State fields for stateful widgets in this page.

  // Controllers and FocusNodes for text fields.
  TextEditingController? petNameController;
  TextEditingController? speciesController;
  TextEditingController? genderController;
  TextEditingController? breedController;
  TextEditingController? ageController;
  TextEditingController? weightController;
  TextEditingController? heightController;

  FocusNode? petNameFocusNode;
  FocusNode? speciesFocusNode;
  FocusNode? genderFocusNode;
  FocusNode? breedFocusNode;
  FocusNode? ageFocusNode;
  FocusNode? weightFocusNode;
  FocusNode? heightFocusNode;

  @override
  void initState(BuildContext context) {
    // Initialize controllers and focus nodes.
    petNameController = TextEditingController();
    speciesController = TextEditingController();
    genderController = TextEditingController();
    breedController = TextEditingController();
    ageController = TextEditingController();
    weightController = TextEditingController();
    heightController = TextEditingController();

    petNameFocusNode = FocusNode();
    speciesFocusNode = FocusNode();
    genderFocusNode = FocusNode();
    breedFocusNode = FocusNode();
    ageFocusNode = FocusNode();
    weightFocusNode = FocusNode();
    heightFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes.
    petNameController?.dispose();
    speciesController?.dispose();
    genderController?.dispose();
    breedController?.dispose();
    ageController?.dispose();
    weightController?.dispose();
    heightController?.dispose();

    petNameFocusNode?.dispose();
    speciesFocusNode?.dispose();
    genderFocusNode?.dispose();
    breedFocusNode?.dispose();
    ageFocusNode?.dispose();
    weightFocusNode?.dispose();
    heightFocusNode?.dispose();
  }

  /// Utility function to clear all input fields.
  void clearFields() {
    petNameController?.clear();
    speciesController?.clear();
    genderController?.clear();
    breedController?.clear();
    ageController?.clear();
    weightController?.clear();
    heightController?.clear();
  }
}
