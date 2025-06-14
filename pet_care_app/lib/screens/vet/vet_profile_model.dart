//import '/common/choice_chips_widget.dart';
//import '/common/icon_button_widget.dart';
//import '/common/app_theme.dart';
import '/common/app_utils.dart';
//import '/common/custom_widgets.dart';
import '/common/form_field_controller.dart';
import 'vet_profile.dart' show VetProfileWidget;
import 'package:flutter/material.dart' show BuildContext;

//import 'package:google_fonts/google_fonts.dart';
//import 'package:provider/provider.dart';

class VetProfileModel
    extends BaseModel<VetProfileWidget> {
      String? picture;
      String? name;
      String? bio;

      
  ///  State fields for stateful widgets in this page.

  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];


  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
