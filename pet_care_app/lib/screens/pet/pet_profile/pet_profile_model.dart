import 'package:pet_care_app/common/app_utils.dart';
import '/common/form_field_controller.dart';
import 'pet_profile_widget.dart' show PetProfileWidget;
import 'package:flutter/material.dart';

class PetProfileModel extends BaseModel<PetProfileWidget> {
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
