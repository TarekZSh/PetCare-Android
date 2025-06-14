//import '/common/choice_chips_widget.dart';
//import '/common/app_theme.dart';
import 'dart:io';

import '/common/app_utils.dart';
//import '/common/custom_widgets.dart';
import '/common/form_field_controller.dart';
//import 'dart:ui';
import 'vet_profile_info.dart' show VetSignUpInfoWidget;
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
//import 'package:provider/provider.dart';

class VetSignUpInfoModel extends BaseModel<VetSignUpInfoWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  File? licenseFile;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? nameController;
  String? Function(BuildContext, String?)? nameControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? bioController;
  String? Function(BuildContext, String?)? bioControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? emailController;
  String? Function(BuildContext, String?)? emailControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? phoneController;
  String? Function(BuildContext, String?)? phoneControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode5;
  TextEditingController? addressController;
  String? Function(BuildContext, String?)? addressControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode6;
  TextEditingController? experienceController;
  String? Function(BuildContext, String?)? experienceControllerValidator;
  // State field(s) for ChoiceChips widget.
  // FocusNode? textFieldFocusNode7;
  // TextEditingController? degreeController;
  // String? Function(BuildContext, String?)? degreeControllerValidator;
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  FocusNode? textFieldFocusNode7;
  TextEditingController? universityController;
  String? Function(BuildContext, String?)? universityControllerValidator;
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    nameController?.dispose();

    textFieldFocusNode2?.dispose();
    bioController?.dispose();

    textFieldFocusNode3?.dispose();
    emailController?.dispose();

    textFieldFocusNode4?.dispose();
    phoneController?.dispose();

    textFieldFocusNode5?.dispose();
    addressController?.dispose();

    textFieldFocusNode6?.dispose();
    experienceController?.dispose();

    textFieldFocusNode7?.dispose();
     universityController?.dispose();
  }
}
