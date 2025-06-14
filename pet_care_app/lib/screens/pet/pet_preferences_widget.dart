import 'package:flutter/material.dart';
import 'package:pet_care_app/common/app_theme.dart';
import 'package:pet_care_app/common/custom_widgets.dart';
import 'package:pet_care_app/firebase/pet_class.dart';

class PetPreferencesSection extends StatefulWidget {
  final Pet pet;
  final Function(Map<String, bool>) onSave;

  PetPreferencesSection({
    required this.pet,
    required this.onSave,
  });

  @override
  _PetPreferencesSectionState createState() => _PetPreferencesSectionState();
}

class _PetPreferencesSectionState extends State<PetPreferencesSection> {
  late Map<String, bool> preferences;
  bool isEditing = false;

  @override
@override
void initState() {
  super.initState();
  
  // Initialize with existing preferences or set default options if empty
  preferences = Map.from(widget.pet.preferences);

  final defaultPreferences = {
    'Open to Walk': false,
    'Open to Breed': false,
    'Open to Play': false,
    'Open to Socialize': false,
  };

  defaultPreferences.forEach((key, value) {
    preferences.putIfAbsent(key, () => value);
  });
}

  void toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void savePreferences() async {
    setState(() {
      isEditing = false;
      widget.pet.preferences = preferences;
    });

    final success = await widget.pet.saveToFirestore();
    if (success) {
      widget.onSave(preferences);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferences Saved!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save Failed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final hasSelectedPreferences = preferences.values.contains(true);
    final hasPreferences = preferences.isNotEmpty;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        screenWidth * 0.01,
        0.0,
        screenWidth * 0.01,
        0.0,
      ),
      child: Container(
        width: screenWidth * 1.0,
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            screenWidth * 0.01,
            screenHeight * 0.01,
            screenWidth * 0.01,
            screenHeight * 0.01,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Preferences',
                        style: appTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter Tight',
                              color: appTheme.of(context).success,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ),
                  Center(
                    child: IconButton(
                      icon: Icon(
                        isEditing ? Icons.close : Icons.add_circle_outline,
                        color: appTheme.of(context).success,
                        size: 24.0,
                      ),
                      onPressed: toggleEditMode,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),

              // If not editing and no selected preferences
              if (!isEditing && !hasSelectedPreferences)
                Padding(
                  padding: EdgeInsets.only(right: screenWidth * 0.1),
                  child: Center(
                    child: Text(
                      'No preferences added.',
                      style:  appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                fontSize: 15.5,
                                letterSpacing: 0.0,
                              ),
                              
                    ),
                  ),
                ),

              // If not editing and there are selected preferences
              if (!isEditing && hasSelectedPreferences)
                Wrap(
                  spacing: screenWidth * 0.02,
                  runSpacing: screenHeight * 0.01,
                  children: preferences.entries
                      .where((entry) => entry.value)
                      .map(
                        (entry) => Chip(
                          label: Text(
                            entry.key,
                            style: appTheme.of(context).bodyMedium,
                          ),
                          backgroundColor:
                              appTheme.of(context).success.withOpacity(0.1),
                        ),
                      )
                      .toList(),
                ),

              // If editing and there are preferences to edit
              if (isEditing && hasPreferences)
                Wrap(
                  spacing: screenWidth * 0.02,
                  runSpacing: screenHeight * 0.01,
                  children: preferences.keys.map((option) {
                    return FilterChip(
                      label: Text(
                        option,
                        style: appTheme.of(context).bodyMedium,
                      ),
                      selected: preferences[option] ?? false,
                      selectedColor: appTheme.of(context).success,
                      backgroundColor:
                          appTheme.of(context).secondaryText.withOpacity(0.1),
                      onSelected: (selected) {
                        setState(() {
                          preferences[option] = selected;
                        });
                      },
                    );
                  }).toList(),
                ),

              // If editing and there are no preferences
              if (isEditing && !hasPreferences)
                Center(
                  child: Text(
                    'No preferences available to add.',
                    style: appTheme.of(context).bodyMedium.override(
                          fontFamily: 'Inter',
                          fontSize: 15.5,
                          letterSpacing: 0.0,
                          color: Colors.grey,
                        ),
                  ),
                ),

              if (isEditing) SizedBox(height: screenHeight * 0.03),

              // Save Button
              if (isEditing)
                Center(
                  child: ButtonWidget(
                    onPressed: hasPreferences ? savePreferences : null,
                    text: 'Save Preferences',
                    options: ButtonOptions(
                      width: MediaQuery.sizeOf(context).width,
                      height: 50.0,
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: hasPreferences
                          ? appTheme.of(context).success
                          : Colors.grey.shade300,
                      textStyle: appTheme.of(context).titleMedium.override(
                            fontFamily: 'Inter Tight',
                            color: hasPreferences ? Colors.white : Colors.grey,
                            letterSpacing: 0.0,
                          ),
                      elevation: hasPreferences ? 2.0 : 0.0,
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
