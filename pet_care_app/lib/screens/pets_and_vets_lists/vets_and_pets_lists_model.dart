import '/common/app_utils.dart';
import '/common/form_field_controller.dart';
import 'vets_and_pets_lists_widget.dart' show VetsandpetslistsWidget;
import 'package:flutter/material.dart';

class VetsandpetslistsModel extends BaseModel<VetsandpetslistsWidget> {

  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
    choiceChipsValueController?.dispose();
  }
}
