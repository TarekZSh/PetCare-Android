import '/common/app_utils.dart';
import '/common/form_field_controller.dart';
import 'vet_patient_list_widget.dart' show VetPatientListWidget;
import 'package:flutter/material.dart';

class VetPatientListModel extends BaseModel<VetPatientListWidget> {
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
