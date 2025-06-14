// import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:pet_care_app/screens/pet/pet_preferences_widget.dart';
import 'package:pet_care_app/services/notifications_service.dart';

import '/common/choice_chips_widget.dart';
import '/common/icon_button_widget.dart';
import '/common/app_theme.dart';
import '/common/app_utils.dart';
import '/common/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'pet_profile_model.dart';
export 'pet_profile_model.dart';
import 'dart:async';
import 'dart:io';
import '../pet_medical_overview/pet_medical_overview_widget.dart';
// import '/providers/auth_provider.dart';
import '../../../services/edit_profile_name_bio.dart';
// import '/providers/app_state_notifier.dart';

class PetProfileWidget extends StatefulWidget {
  final Pet pet;

  const PetProfileWidget({required this.pet, super.key});

  @override
  State<PetProfileWidget> createState() => _PetProfileWidgetState();
}

class _PetProfileWidgetState extends State<PetProfileWidget> {
  late PetProfileModel _model;
  late Pet _pet;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  String? imageUrl;
  String _gender = 'Male';
  String _breed = 'Not specified';
  String _owner = 'No owner assigned';
  String _type = 'Unknown';
  String _originalType = '';
  String _originalGender = '';
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();

  final logger = Logger();

  String _currentView = 'Profile';

  final scaffoldKey = GlobalKey<ScaffoldState>();

   List<Map<String, dynamic>> events = [];

  @override
  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _model = createModel(context, () => PetProfileModel());

    // Initialize controllers with values from the Pet object
    _weightController = TextEditingController(text: _pet.weight.toString());
    _heightController = TextEditingController(text: _pet.height.toString());
    _ageController = TextEditingController(text: _pet.age.toString());
    _nameController = TextEditingController(text: _pet.name);
    _bioController = TextEditingController(text: _pet.bio);

    // Initialize profile fields with values from the Pet object
    _gender = _pet.gender.isNotEmpty ? _pet.gender : 'Male';
    _breed = _pet.breed.isNotEmpty ? _pet.breed : 'Not specified';
    _owner = _pet.owner.isNotEmpty ? _pet.owner : 'No owner assigned';
    _type = _pet.species.isNotEmpty ? _pet.species : 'Unknown';
    _originalType = _type; // Store original type
    _originalGender = _gender; // Store original gender

    // Initialize health-related fields
    _weight = _pet.weight > 0 ? _pet.weight.toString() : '0';
    _height = _pet.height > 0 ? _pet.height.toString() : '0';
    _age = _pet.age > 0 ? _pet.age.toString() : '0';
    _originalAge = _age; // Store the original age

    specialNotes = List<Map<String, String>>.from(_pet.specialNotes);
    lastActivities = List<String>.from(_pet.lastActivities);
    // Add listeners to validate input
    _weightController.addListener(() {
      _validateField(_weightController, (error) => _weightError = error, '*');
    });
    _heightController.addListener(() {
      _validateField(_heightController, (error) => _heightError = error, '*');
    });
    _ageController.addListener(() {
      _validateField(_ageController, (error) => _ageError = error, '*');
    });

    imageUrl = _pet.imageUrl;

     events = [];
      events.addAll(_pet.events);
      events.addAll(_pet.vetEvents);
  }

   

  @override
  void dispose() {
    // Dispose the model
    _model.dispose();

    // Remove listeners before disposing controllers
    _weightController.removeListener(() => _validateField(
        _weightController, (error) => _weightError = error, '*'));
    _heightController.removeListener(() => _validateField(
        _heightController, (error) => _heightError = error, '*'));
    _ageController.removeListener(() =>
        _validateField(_ageController, (error) => _ageError = error, '*'));

    // Dispose of text controllers
    _ownerController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _nameController.dispose();

    // Call super.dispose() at the end
    super.dispose();
  }

///////////// Edit pet details
  bool _isEditingDetails = false;

  final List<String> _animalTypes = [
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
  ];

  void _toggleEditingDetails() {
    setState(() {
      _isEditingDetails = !_isEditingDetails;

      if (_isEditingDetails) {
        // Populate text fields with existing values
        _ownerController.text = _owner == 'No owner assigned' ? '' : _owner;
        _breedController.text = _breed == 'Not specified' ? '' : _breed;
        _originalType = _type;
        _originalGender = _gender;
      } else {
        // Update local variables with edited values
        _owner = _ownerController.text.isNotEmpty
            ? _ownerController.text
            : 'No owner assigned';
        _breed = _breedController.text.isNotEmpty
            ? _breedController.text
            : 'Not specified';
      }
    });
  }

  void _saveChangesDetails() async {
    setState(() {
      // Update local variables
      _owner = _ownerController.text.isNotEmpty
          ? _ownerController.text
          : 'No owner assigned';
      _breed = _breedController.text.isNotEmpty
          ? _breedController.text
          : 'Not specified';

      // Assume the `Pet` object is accessible as `_pet`
      _pet.owner = _owner;
      _pet.breed = _breed;
      _pet.species = _type;
      _pet.gender = _gender;

      // Exit editing mode
      _isEditingDetails = false;
    });

    // Save changes to Firestore
    final success = await _pet.updateToFirestore();
    if (success) {
      logger.d('Pet details updated successfully');
    } else {
      logger.e('Failed to update pet details');
    }
  }

  void _cancelEditingDetails() {
    setState(() {
      _isEditingDetails = false;
      _ownerController.text = _owner == 'No owner assigned' ? '' : _owner;
      _breedController.text = _breed == 'Not specified' ? '' : _breed;
      _type = _originalType;
      _gender = _originalGender;
    });
  }

//////////////Edit health overview///////
  bool _isEditingHealth = false;
  String _weight = '';
  String _height = '';
  String _age = '';
  String _weightError = '';
  String _heightError = '';
  String _ageError = '';
  String _originalAge = '';

  void _validateField(TextEditingController controller,
      Function(String) setError, String errorMessage) {
    setState(() {
      setError(controller.text.isEmpty ? errorMessage : '');
    });
  }

  void _toggleEditingHealth() {
    setState(() {
      _isEditingHealth = !_isEditingHealth;
      if (_isEditingHealth) {
        _originalAge = _age;
        _ownerController.text = _weight;
        _ownerController.text = _height;
        _ownerController.text = _age;
      }
    });
  }

  void _saveChangesHealth() async {
    setState(() {
      // Reset error messages
      _weightError = '';
      _heightError = '';
      _ageError = '';

      // Validate fields
      if (_weightController.text.isEmpty) {
        _weightError = '*';
        logger.e('Weight field is empty');
      }
      if (_heightController.text.isEmpty) {
        _heightError = '*';
        logger.e('Height field is empty');
      }
      if (_ageController.text.isEmpty) {
        _ageError = '*';
        logger.e('Age field is empty');
      }

      // If no errors, update local variables
      if (_weightError.isEmpty && _heightError.isEmpty && _ageError.isEmpty) {
        _weight = _weightController.text;
        _height = _heightController.text;
        _age = _ageController.text;

        // Log local updates
        logger.d(
            'Health details updated locally: Weight: $_weight, Height: $_height, Age: $_age');

        // Update Pet object
        _pet.weight = double.tryParse(_weight) ?? 0.0;
        _pet.height = double.tryParse(_height) ?? 0.0;
        _pet.age = double.tryParse(_age) ?? 0.0;

        // Exit editing mode
        _isEditingHealth = false;
      } else {
        logger.e('Failed to update health details due to validation errors.');
      }
    });

    // Save changes to Firestore
    if (_weightError.isEmpty && _heightError.isEmpty && _ageError.isEmpty) {
      try {
        final success = await _pet.updateToFirestore();
        if (success) {
          logger.d('Health details successfully saved to Firestore.');
        } else {
          throw Exception('Failed to save health details to Firestore.');
        }
      } catch (e) {
        logger.e('Error saving health details to Firestore: $e');
      }
    }
  }

  void _cancelEditingHealth() {
    _cancelAddItem(_weightController, (bool value) {
      // Revert to original values
      _isEditingHealth = value;
      _weightController.text = _weight;
      _heightController.text = _height;
      _age = _originalAge;
      _ageController.text = _age;

      // Reset error messages
      _weightError = '';
      _heightError = '';
      _ageError = '';

      // Log cancellation
      logger
          .d('Editing health details cancelled. Reverted to original values.');
      logger
          .d('Original values: Weight: $_weight, Height: $_height, Age: $_age');
    });
  }

/*calcualte age*/
  DateTime? _birthDate;

  void _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: "Select your pet birthday",
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        _age = _calculateAge(picked).toStringAsFixed(2);
        _ageController.text = _age;
      });
    }
  }

  double _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int years = today.year - birthDate.year;
    int months = today.month - birthDate.month;
    if (months < 0 || (months == 0 && today.day < birthDate.day)) {
      years--;
      months += 12;
    }
    double age = years + (months / 100);
    return age;
  }

////////////add and delete notes or activites/////////////
  List<Map<String, String>> specialNotes = [];
  List<String> lastActivities = [];

  bool _isAddingNote = false;
  bool _isAddingActivity = false;
  bool _isNoteEmpty = false;
  bool _isActivityEmpty = false;
  bool _isActivityFound = false;
  bool _isNoteFound = false;
  String _selectedStyle = 'Allergies';

  void _toggleAddItem(bool isAdding, Function(bool) setStateCallback) {
    setState(() {
      setStateCallback(!isAdding);
    });
  }

  void _cancelAddItem(
      TextEditingController controller, Function(bool) setStateCallback) {
    setState(() {
      controller.clear();
      setStateCallback(false);
      _isNoteEmpty = false;
      _isActivityEmpty = false;
      _isNoteFound = false;
      _isActivityFound = false;
    });
  }

  void _deleteItem(int index, List<dynamic> list) async {
    setState(() {
      list.removeAt(index);
    });
    await _updateFirestore(); // Save to Firestore
  }

  Future<bool?> _confirmDeleteItem(
      int index, List<dynamic> list, String itemType) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this $itemType?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: appTheme.of(context).success,
                foregroundColor: Colors.white,
              ),
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: appTheme.of(context).success,
                foregroundColor: Colors.white,
              ),
              child: Text('Yes'),
              onPressed: () {
                _deleteItem(index, list);
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editNote(int index) async {
    final note = specialNotes[index];
    _noteController.text = note['text']!;
    _selectedStyle = note['style']!;
    final String originalStyle = _selectedStyle;

    void _updateState() {
      if (_noteController.text.isNotEmpty) {
        setState(() {
          _isNoteEmpty = false;
        });
      }
      bool noteExists = specialNotes.any((n) =>
          n['text'] == _noteController.text &&
          n['style'] == _selectedStyle &&
          n != note);
      if (!noteExists) {
        setState(() {
          _isNoteFound = false;
        });
      }
    }

    _noteController.addListener(_updateState);

   await showDialog<void>(
  context: context,
  builder: (BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter dialogSetState) {
        return AlertDialog(
          title: Text('Edit Note'),
          content: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Enter note',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      errorText: _isNoteEmpty ? 'Note cannot be empty' : null,
                    ),
                     maxLines: null, // Allows the TextField to grow dynamically
                    minLines: 1, // Starts with a single line
                    onChanged: (text) {
                      dialogSetState(() {
                        _isNoteEmpty = text.isEmpty;
                        _isNoteFound = specialNotes.any((n) =>
                            n['text'] == text &&
                            n['style'] == _selectedStyle &&
                            n != note);
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  child: Row(
    children: [
      Text(
        'Note Type:',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Inter',
              letterSpacing: 0.0,
            ),
      ),
      SizedBox(width: 8.0),
      Expanded(
        child: DropdownButtonFormField<String>(
          value: _selectedStyle,
          onChanged: (String? newValue) {
            if (newValue != null) {
              dialogSetState(() {
                _selectedStyle = newValue;
                _isNoteFound = specialNotes.any((note) =>
                    note['text'] == _noteController.text &&
                    note['style'] == _selectedStyle);
              });
            }
          },
          items: <String>[
            'Allergies',
            'Medical Conditions',
            'Behavioral Notes'
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ],
  ),
),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                        backgroundColor: appTheme.of(context).success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    bool noteExists = specialNotes.any((n) =>
                        n['text'] == _noteController.text &&
                        n['style'] == _selectedStyle &&
                        n != note);
                    setState(() {
                      _isNoteEmpty = _noteController.text.isEmpty;
                      _isNoteFound = noteExists;
                    });

                    if (_isNoteEmpty) return;

                    if (_isNoteFound) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Note already exists!',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      specialNotes[index] = {
                        'text': _noteController.text,
                        'style': _selectedStyle,
                      };
                    });
                    await _updateFirestore(); // Save to Firestore
                    _noteController.removeListener(_updateState);
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
                SizedBox(width: 16.0),
                TextButton(
                  style: TextButton.styleFrom(
                        backgroundColor: appTheme.of(context).success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    dialogSetState(() {
                      _selectedStyle = originalStyle;
                    });
                    _noteController.removeListener(_updateState);
                    _cancelAddItem(
                        _noteController, (value) => _isAddingNote = value);
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          ],
        );
      },
    );
  },
);

    _noteController.removeListener(_updateState);
  }

  Future<void> _updateFirestore() async {
    try {
      _pet.specialNotes = specialNotes;
      _pet.lastActivities = lastActivities;
      final success = await _pet.updateToFirestore();
      if (success) {
        logger.d('Changes saved to Firestore.');
      } else {
        logger.e('Failed to save changes to Firestore.');
      }
    } catch (e) {
      print('Error saving to Firestore: $e');
    }
  }

//////////////edit activity//////////

  Future<void> _editActivity(int index) async {
    final activity =
        _pet.lastActivities[index]; // Access activity from Pet object
    _activityController.text = activity;

    void _updateState() {
      if (_activityController.text.isNotEmpty) {
        setState(() {
          _isActivityEmpty = false;
          _isActivityFound =
              _pet.lastActivities.contains(_activityController.text);
        });
      }
    }

    _activityController.addListener(_updateState);

    await showDialog<void>(
  context: context,
  builder: (BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter dialogSetState) {
        return AlertDialog(
          title: Text('Edit Activity'),
          content: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _activityController,
                    decoration: InputDecoration(
                      hintText: 'Enter activity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                                         maxLines: null, // Allows the TextField to grow dynamically
                    minLines: 1,
                    onChanged: (text) {
                      dialogSetState(() {
                        _isActivityEmpty = text.isEmpty;
                        _isActivityFound = _pet.lastActivities
                            .where((activity) => activity != _pet.lastActivities[index])
                            .contains(text);
                      });
                    },
                  ),
                  if (_isActivityEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Activity cannot be empty',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_isActivityFound)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Activity already exists',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: appTheme.of(context).success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() {
                      _isActivityEmpty = _activityController.text.isEmpty;
                      _isActivityFound = _pet.lastActivities
                          .where((activity) => activity != _pet.lastActivities[index])
                          .contains(_activityController.text);
                    });

                    if (_isActivityEmpty || _isActivityFound) {
                      return;
                    }

                    setState(() {
                      _pet.lastActivities[index] = _activityController.text;
                    });

                    // Update Firestore
                    try {
                      final success = await _pet.updateToFirestore();
                      if (success) {
                        print('Activity updated successfully in Firestore.');
                      } else {
                        print('Failed to update activity in Firestore.');
                      }
                    } catch (e) {
                      print('Error updating activity in Firestore: $e');
                    }

                    _activityController.clear();
                    _activityController.removeListener(_updateState);
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
                SizedBox(width: 16.0),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: appTheme.of(context).success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    dialogSetState(() {
                      _activityController.clear(); // Revert to the original activity
                    });
                    _activityController.removeListener(_updateState);
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          ],
        );
      },
    );
  },
);
    _activityController.removeListener(_updateState);
  }

  String name = 'Example';
  String bio = 'some bio';
  File? _profileImage;




 ////////////////////////////mays//////////////////

bool areMapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
  if (map1.length != map2.length) return false;
  for (String key in map1.keys) {
    if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
  }
  return true;
}

  void updatePetEvents() {
      events = [];
      events.addAll(_pet.events);
      events.addAll(_pet.vetEvents);
  }

  void addEvent(Map<String, dynamic> event) async{
    logger.d('Adding event: $event');
      _pet.events.add(event);
      logger.d('the pet events are ${_pet.events}'); // Notify listeners about the change
      await _pet.saveToFirestore();
    setState(() {
      updatePetEvents();
    });
  }

  void updateEvent(int index, Map<String, dynamic> event) {
    final eventToFind = events[index];
    bool isVetEvent = false;
    var eventIndex = _pet.events.indexWhere((event) => areMapsEqual(event, eventToFind));
    if(eventIndex == -1) {
         isVetEvent = true;
        eventIndex = _pet.vetEvents.indexWhere((event) => areMapsEqual(event, eventToFind));
    }
    setState(() {
     isVetEvent? _pet.vetEvents[eventIndex] = event : _pet.events[eventIndex] = event; // Notify listeners about the change
      _pet.saveToFirestore();
      updatePetEvents();
    });
  }

  void deleteEvent(int index) async{
    final eventToFind = events[index];
    bool isVetEvent = false;
    var eventIndex = _pet.events.indexWhere((event) => areMapsEqual(event, eventToFind));
    if(eventIndex == -1) {
         isVetEvent = true;
        eventIndex = _pet.vetEvents.indexWhere((event) => areMapsEqual(event, eventToFind));
    }
          isVetEvent? _pet.vetEvents.removeAt(eventIndex) : _pet.events.removeAt(eventIndex); // Notify listeners about the change
      await _pet.saveToFirestore();
      updatePetEvents();
    setState(() {
    });
  }

  //void _addFinishedEvent(Map<String, dynamic> event) {

  void _addFinishedEvent(Map<String, dynamic> event) {
  
    List<Map<String, String>>list = event['eventType'] == 'Health and Wellness'
        ? _pet.medicalHistory
        : _pet.vaccinations;
    bool EventExists = list.any((info) =>
        info['title'] == event['title'] &&
        info['date'] == formatEventDateTime(event['date'], '', context) &&
        info['doctor'] == event['doctorName']);
    if (EventExists) {
      return;
    }

    Map<String, String> item = {
      'date': formatEventDateTime(event['date'], '', context),
      'doctor': event['doctorName'],
      'title': event['title'],
    };
    setState(() {
      list.add(item);
      _pet.saveToFirestore();
    });
  }

  Future<bool?> _confirmDeleteEvent(Map<String, dynamic> eventDetails, int index,{bool isDoctor = false, done = false}) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(done ? 'Confirm Completion' : 'Confirm Deletion'),
          content: Text(done
              ? 'Please confirm that the scheduled event is finished.'
              : 'Are you sure you want to delete this event?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: appTheme.of(context).success,
                foregroundColor: Colors.white,
              ),
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: appTheme.of(context).success,
                foregroundColor: Colors.white,
              ),
              child: Text('Yes'),
              onPressed: () {
                deleteEvent(index);
                if (done &&
                    !isDoctor &&
                    (eventDetails['eventType'] == 'Health and Wellness' ||
                        eventDetails['eventType'] == 'Vaccination')) {
                  _addFinishedEvent(eventDetails);
                  print('Done button pressed');
                }
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
TimeOfDay _parseTime(String time) {
  try {
    final format24Hour = DateFormat.Hm(); // 24-hour format
    final format12Hour = DateFormat('h:mm a'); // Explicit 12-hour format with AM/PM
    logger.d('Time to parse: $time');

    // Clean and normalize the input time
    String cleanedTime = time.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleanedTime = cleanedTime.toUpperCase(); // Normalize case
    cleanedTime = cleanedTime.replaceAll(RegExp(r'[^\x20-\x7E]'), ''); // Remove non-ASCII chars
    logger.d('Cleaned Time: $cleanedTime');

    DateTime dateTime;
    if (cleanedTime.contains(RegExp(r'[AP]M'))) {
      logger.d('Time contains AM/PM');
      dateTime = format12Hour.parse(cleanedTime);
    } else {
      logger.d('Time does not contain AM/PM');
      dateTime = format24Hour.parse(cleanedTime);
    }

    logger.d('Parsed time: $dateTime');
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  } catch (e) {
    logger.e('Error parsing time: $e');
    return TimeOfDay(hour: 0, minute: 0);
  }
}



  void _showAddEditEventDialog(int index, bool isAdding, String type) {
    final titleController = TextEditingController(text: isAdding ? '' : events[index]['title']);
    DateTime? selectedDate = isAdding ? null : DateTime.parse(events[index]['date']);
    TimeOfDay? selectedTime = isAdding ? null : _parseTime(events[index]['time']);
    String? eventType = isAdding ? null : events[index]['eventType'];
    final doctorNameController = TextEditingController(
        text: isAdding ? '' : events[index]['doctorName']);
    final shaverNameController = TextEditingController(
        text: isAdding ? '' : events[index]['shaverName']);
    final notesController =
        TextEditingController(text: isAdding ? '' : events[index]['notes']);
    DateTime? oldDate = selectedDate;
    TimeOfDay? oldTime = selectedTime;

showDialog(
  context: context,
  builder: (context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(isAdding ? "Add New Event" : "Edit Event"),
          content: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Title",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(width: 4), // Add space between the texts
                        Text(
                          "*",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: "Enter title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    Row(
                      children: [
                        Text(
                          "Date",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(width: 4), // Add space between the texts
                        Text(
                          "*",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    ListTile(
                      title: Text(selectedDate == null
                          ? "Choose Date"
                          : DateFormat('MMMM dd, yyyy').format(selectedDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: (selectedDate != null && selectedDate!.isBefore(DateTime.now())) ? DateTime.now() : selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          "Time",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(width: 4), // Add space between the texts
                        Text(
                          "*",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    ListTile(
                      title: Text(selectedTime == null
                          ? "Choose Time"
                          : selectedTime!.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    Divider(),
                     if (type != 'doctor')
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            "Event Type",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(width: 4), // Add space between the texts
          Text(
            "*",
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      DropdownButtonFormField<String>(
        value: eventType,
        items: [
          'Health and Wellness',
          'Vaccination',
          'Grooming',
          'Other',
        ]
            .map((type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            eventType = value;
          });
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
    ],
  ),
                    SizedBox(height: 16),
                    if (eventType == 'Health and Wellness' ||
                        eventType == 'Vaccination') ...[
                      Row(
                        children: [
                          Text(
                            "Doctor Name",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(width: 4), // Add space between the texts
                          Text(
                            "*",
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      TextField(
                        controller: doctorNameController,
                        decoration: const InputDecoration(
                          hintText: "Enter doctor's name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (eventType == 'Grooming') ...[
                      Row(
                        children: [
                          Text(
                            "Shaver Name",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(width: 4), // Add space between the texts
                          Text(
                            "*",
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      TextField(
                        controller: shaverNameController,
                        decoration: const InputDecoration(
                          hintText: "Enter shaver's name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (eventType == 'Other')
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          hintText: "Notes",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        maxLength: 50,
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async{
                if (titleController.text.isEmpty ||
                    selectedDate == null ||
                    selectedTime == null ||
                    eventType == null ||
                    ((eventType == 'Health and Wellness' || eventType == 'Vaccination') && doctorNameController.text.isEmpty) ||
                    (eventType == 'Grooming' && shaverNameController.text.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all required fields!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                DateTime oldEventDate;
                if (oldDate != null && oldTime != null) {
                  oldEventDate = oldDate.add(Duration(
                  hours: oldTime.hour,
                  minutes: oldTime.minute,
                  ));
                } else {
                  oldEventDate = DateTime.now();
                }

                DateTime oldFirstNotificationTime = oldEventDate.subtract(Duration(minutes: 1440));
                DateTime oldSecondNotificationTime = oldEventDate.subtract(Duration(minutes: 60));
                DateTime oldThirdNotificationTime = oldEventDate.subtract(Duration(minutes: 5));

                if(!isAdding)
                {
                    await NotificationService.cancelNotification(oldFirstNotificationTime.millisecondsSinceEpoch ~/ 1000);
                    await NotificationService.cancelNotification(oldSecondNotificationTime.millisecondsSinceEpoch ~/ 1000);
                    await NotificationService.cancelNotification(oldThirdNotificationTime.millisecondsSinceEpoch ~/ 1000);
                }



                final newEvent = {
                  'title': titleController.text,
                  'petId': _pet.id,
                  'date': selectedDate?.toIso8601String() ?? '',
                  'time': selectedTime?.format(context) ?? '',
                  'eventType': eventType,
                  'doctorName': doctorNameController.text,
                  'shaverName': shaverNameController.text,
                  'notes': notesController.text,
                };
                bool eventExists = events.any((event) =>
                    event['title'] == newEvent['title'] &&
                    event['petId'] == newEvent['petId'] &&
                    event['date'] == newEvent['date'] &&
                    event['time'] == newEvent['time'] &&
                    event['eventType'] == newEvent['eventType'] &&
                    event['doctorName'] == newEvent['doctorName'] &&
                    event['shaverName'] == newEvent['shaverName'] &&
                    event['notes'] == newEvent['notes']);

                if (eventExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("This event already exists!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (isAdding) {
                  addEvent(newEvent);
                } else {
                  updateEvent(index, newEvent);
                }

                DateTime eventDate = selectedDate!.add(Duration(
                  hours: selectedTime!.hour,
                  minutes: selectedTime!.minute,
                ));

                
                // String eventTitle = titleController.text;
                DateTime firstNotificationTime = eventDate.subtract(Duration(minutes: 1440));
                DateTime secondNotificationTime = eventDate.subtract(Duration(minutes: 60));
                DateTime thirdNotificationTime = eventDate.subtract(Duration(minutes: 5));

                
                // String eventTitle = titleController.text;
                // logger.f('the new ${firstNotificationTime.millisecondsSinceEpoch ~/ 1000} and the eventDate is $eventDate');
                
                if (firstNotificationTime.isAfter(DateTime.now())) {
                  NotificationService.scheduleNotification(
                    id: firstNotificationTime.millisecondsSinceEpoch ~/ 1000,
                    title: newEvent['title'] ?? '',
                    body: "don't miss your event",
                    notificationTime: firstNotificationTime,
                  );
                }
                if (secondNotificationTime.isAfter(DateTime.now())) {
                  NotificationService.scheduleNotification(
                    id: secondNotificationTime.millisecondsSinceEpoch ~/ 1000,
                    title: newEvent['title'] ?? '',
                    body: "don't miss your event",
                    notificationTime: secondNotificationTime,
                  );
                }
                if (thirdNotificationTime.isAfter(DateTime.now())) {
                  NotificationService.scheduleNotification(
                    id: thirdNotificationTime.millisecondsSinceEpoch ~/ 1000,
                    title: newEvent['title'] ?? '',
                    body: "don't miss your event",
                    notificationTime: thirdNotificationTime,
                  );
                }
                
                Navigator.pop(context);
              },
              child: Text(isAdding ? "Add" : "Save"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  },
);
  }

String formatEventDateTime(String date, String time, BuildContext context) {
  // Parse the date string to DateTime
  DateTime parsedDate = DateTime.parse(date);

  // Parse the time string to TimeOfDay
  TimeOfDay parsedTime = _parseTime(time);

  // Format the date
  String formattedDate = DateFormat('MMMM dd, yyyy').format(parsedDate);

  // Format the time
  String formattedTime = parsedTime.format(context);

  return '$formattedDate, $formattedTime';
}

  Widget buildEvent(
      Map<String, dynamic> eventDetails, String eventType, String userTybe) {
    // Define the icon, color, and other details based on eventType
    IconData icon;
    Color iconColor;
    Color backgroundColor;
    String title;
    String petNameText;

    switch (eventType) {
      case 'Health and Wellness':
        icon = Icons.medical_services;
        iconColor = appTheme.of(context).success;
        backgroundColor = Color(0xFFE8F5E9);
        title = eventDetails['title'];
        petNameText = 'For ${_pet.name}';
        break;
      case 'Vaccination':
        icon = Icons.vaccines;
        iconColor = Colors.orange;
        backgroundColor = Color(0xFFFFF3E0);
        title = eventDetails['title'];
        petNameText = 'For ${_pet.name}';
        break;
      case 'Grooming':
        icon = Icons.content_cut;
        iconColor = Colors.blue;
        backgroundColor = Color(0xFFE3F2FD);
        title = eventDetails['title'];
        petNameText = 'For ${_pet.name}';
        break;
      case 'Other':
        icon = Icons.pets;
        iconColor = Color(0xFF969224);
        backgroundColor = Color(0xFFEEEFD8);
        title = eventDetails['title'];
        petNameText = 'For ${_pet.name}';
        break;
      default:
        // For unknown event types, show basic ListTile
        return ListTile(
          title: Text(eventDetails['title']),
          subtitle:
              Text('${eventDetails['petName']} - ${eventDetails['eventType']}'),
        );
    }

    return Container(
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 30,
              ),
            ),
            SizedBox(width: 16), // Space between icon and text
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: appTheme.of(context).bodyLarge.override(
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  // Pet name (or doctor/shaver name as appropriate)
                  if (userTybe != 'pet')
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        petNameText,
                        style: appTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  // Date and time
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                       formatEventDateTime(eventDetails['date'], eventDetails['time'], context),
                      style: appTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            color: appTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                  // Doctor/Shaver/Notes
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: eventType == 'Grooming'
                        ? Text(
                            eventDetails['shaverName'],
                            style: appTheme.of(context).bodySmall.override(
                                  fontFamily: 'Inter',
                                  letterSpacing: 0.0,
                                ),
                          )
                        : eventType == 'Other' &&
                                eventDetails['notes'] != null &&
                                eventDetails['notes'].isNotEmpty
                            ? Text(
                                eventDetails['notes'],
                                style: appTheme.of(context).bodySmall.override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              )
                            : (userTybe != 'doctor' &&
                                    (eventType == 'Health and Wellness' ||
                                        eventType == 'Vaccination'))
                                ? Text(
                                    'Dr. ${eventDetails['doctorName']}',
                                    style:
                                        appTheme.of(context).bodySmall.override(
                                              fontFamily: 'Inter',
                                              letterSpacing: 0.0,
                                            ),
                                  )
                                : Container(),
                  ),
                ],
              ),
            ),
           CircleAvatar(
            backgroundColor: appTheme.of(context).success.withOpacity(0.4),
            radius: MediaQuery.of(context).size.width * 0.05, // 10% of screen width / 2
            child: IconButton(
              onPressed: () {
                int index = events.indexWhere((event) => areMapsEqual(event, eventDetails));
                _confirmDeleteEvent(eventDetails, index, isDoctor: false, done: true);
                print('Done button pressed');
              },
              icon: Icon(
                Icons.check,
                size: MediaQuery.of(context).size.width * 0.05, // Adjust the size as needed
                color: Colors.white, // Set the icon color to white for better contrast
              ),
              tooltip: 'Mark as Done',
            ),
          ),
          ],
        ),
      ),
    );
  }

void sortEventsByDateTime(List<Map<String, dynamic>> events) {
  events.sort((a, b) {
    DateTime dateTimeA = _parseDateTime(a['date'], a['time']);
    DateTime dateTimeB = _parseDateTime(b['date'], b['time']);
    return dateTimeA.compareTo(dateTimeB);
  });
}

DateTime _parseDateTime(String date, String time) {
  final dateFormat = DateFormat('yyyy-MM-dd'); // Adjust the format as needed
  final timeFormat = DateFormat.Hm(); // or use DateFormat.Hm() for 24-hour format
  DateTime parsedDate = dateFormat.parse(date);
  DateTime parsedTime = timeFormat.parse(time);
  return DateTime(
    parsedDate.year,
    parsedDate.month,
    parsedDate.day,
    parsedTime.hour,
    parsedTime.minute,
  );
}


  Widget buildUpComingEventsWidget(String userType) {
    print('in the func');

  sortEventsByDateTime(events);
    
    return Column(
    children: [
      SizedBox(height: 16), // Add a SizedBox at the top
      events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    color: Colors.grey,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No events scheduled',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true, // Prevents unbounded height error
              physics: NeverScrollableScrollPhysics(), // Avoid nested scrolling conflict
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Column(
                  children: [
                    Dismissible(
                      key: Key(event['title']),
                      background: Container(
                        color: Colors.grey,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 20),
                        child: Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _showAddEditEventDialog(index, false, 'pet');
                          return false;
                        } else if (direction == DismissDirection.endToStart) {
                          return await _confirmDeleteEvent(event, index);
                        }
                        return false;
                      },
                      child: buildEvent(event, event['eventType'] ?? 'Health and Wellness', 'pet'),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Add a SizedBox between each event
                  ],
                );
              },
            ),
    ],
  );
  }


  //////////////////////build////////////////
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = 24.0;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: appTheme.of(context).primaryBackground,
        floatingActionButton: _buildFAB(),
        body: Stack(
          children: [
            _buildBackGround(),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  
                    SizedBox(height: 8), // Add some space above the row
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              top: 35), // Adjust the value as needed
                          child: appIconButton(
                            borderRadius: 20,
                            buttonSize: 40,
                            fillColor: Color(0x33FFFFFF),
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () {
                              context.pop();
                              print('IconButton pressed ...');
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _nameController.text = _pet.name;
                            _bioController.text = _pet.bio;
                            showEditProfileDialog(
                              context,
                              _nameController,
                              _bioController,
                              imageUrl,
                              name,
                              bio,
                              (imageFile, newImageUrl) {
                                // Handle image selection
                                setState(() {
                                  _profileImage = imageFile;
                                  imageUrl = newImageUrl;
                                });
                              },
                              () {
                                // Handle image deletion
                                setState(() {
                                  _profileImage = null;
                                  imageUrl = '';
                                });
                              },
                            ).then((bool result) {
                              if (result) {
                                // If Save was clicked, update local state immediately
                                setState(() {
                                  name = _nameController.text;
                                  bio = _bioController.text;
                                  logger.d('the old image is $imageUrl');
                                  imageUrl = (_profileImage == null && imageUrl == '') ? null : imageUrl;// Temporary update
                                  logger.d('The new image is $_profileImage');
                                  logger.d('The new image URL is $imageUrl');
                                  _pet.imageUrl = imageUrl; 
                                });

                                // Perform Firebase and Firestore updates asynchronously
                                Future.microtask(() async {

                                    // Update the Pet object with new values
                                    _pet.name = name;
                                    _pet.bio = bio;
                                    _pet.imageUrl = imageUrl;
                                    logger.d(
                                        'The pet image URL is ${_pet.imageUrl}');

                                    // Save changes to Firestore
                                    await _pet.updateToFirestore();
                                    logger
                                        .d('Pet profile updated in Firestore');
                                });
                              } else {
                                // If Cancel was clicked, revert any local changes
                                setState(() {
                                  _nameController.text = name;
                                  _bioController.text = bio;
                                  _profileImage = null; // Reset profile image
                                  imageUrl = imageUrl; // Keep the current image
                                });
                              }
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: 35.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x33FFFFFF),
                              ),
                              width: iconSize * 1.5,
                              height: iconSize * 1.5,
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: iconSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildProfilePicture(screenWidth, screenHeight),

                    Material(
                      color: Colors.transparent,
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Container(
                        width: screenWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 20.0, 20.0, 20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: appChoiceChips(
                                  options: [
                                    ChipData('Profile'),
                                    ChipData('Medical Overview'),
                                    ChipData('Schedule'),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _model.choiceChipsValue =
                                          val?.firstOrNull;
                                      _currentView =
                                          val?.firstOrNull ?? 'Profile';
                                    });
                                  },
                                  selectedChipStyle: ChipStyle(
                                    backgroundColor:
                                        appTheme.of(context).success,
                                    textStyle: appTheme
                                        .of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Inter',
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                        ),
                                    iconColor: appTheme.of(context).primaryText,
                                    iconSize: 18.0,
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(25.0),
                                  ),
                                  unselectedChipStyle: ChipStyle(
                                    backgroundColor: Color(0xFFF5F5F5),
                                    textStyle:
                                        appTheme.of(context).bodySmall.override(
                                              fontFamily: 'Inter',
                                              color: appTheme
                                                  .of(context)
                                                  .secondaryText,
                                              letterSpacing: 0.0,
                                            ),
                                    iconColor: appTheme.of(context).primaryText,
                                    iconSize: 18.0,
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(25.0),
                                  ),
                                  chipSpacing: screenWidth * 0.01,
                                  rowSpacing: screenHeight * 0.02,
                                  multiselect: false,
                                  initialized: _model.choiceChipsValue != null,
                                  alignment: WrapAlignment.start,
                                  controller:
                                      _model.choiceChipsValueController ??=
                                          FormFieldController<List<String>>(
                                    ['Profile'],
                                  ),
                                  wrapped: true,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              _buildProfileOrOverview(),
                              
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOrOverview() {
    // Dynamically render content based on the current view
    if (_currentView == 'Profile') {
      return _buildProfileView();
    } else if (_currentView == 'Medical Overview') {
      return PetMedicalOverviewWidget(
        pet: _pet,
      ); // Return the widget instance directly
    } else {
      return buildUpComingEventsWidget('pet'); // Placeholder for other views
    }
  }

Widget _buildProfileView() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildPetDetails(),
      const SizedBox(height: 16.0),
      _buildHealthOverview(),
      const SizedBox(height: 16.0),
      _buildSpecialNotes(),
      const SizedBox(height: 16.0),
      _buildLastActivities(),
      const SizedBox(height: 16.0),
      // Add the Preferences Section here
      PetPreferencesSection(
        pet: _pet, // Pass the Pet object
        onSave: (updatedPreferences) {
          setState(() {
            _pet.preferences = updatedPreferences;
          });
        },
      ),
    ],
  );
}


  Widget _buildPetDetails() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = 24.0;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          screenWidth * 0.01, 0.0, screenWidth * 0.01, 0.0),
      child: Container(
        width: screenWidth * 1.0,
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(screenWidth * 0.03,
              screenHeight * 0.03, screenWidth * 0.03, screenHeight * 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Pet Details',
                        style: appTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter Tight',
                              color: appTheme.of(context).success,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ),
                  if (!_isEditingDetails)
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: appTheme.of(context).success,
                        size: iconSize,
                      ),
                      onPressed: _toggleEditingDetails,
                    ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              Table(
                columnWidths: {
                  0: FlexColumnWidth(1),
                  1: FixedColumnWidth(screenWidth * 0.33),
                  2: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gender',
                            style: appTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: appTheme.of(context).secondaryText,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          _isEditingDetails
                              ? DropdownButton<String>(
                                  value: _gender,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _gender = newValue!;
                                    });
                                  },
                                  items: <String>['Male', 'Female', 'Other']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                )
                              : Text(
                                  _gender,
                                  style:
                                      appTheme.of(context).bodyLarge.override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type',
                            style: appTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: appTheme.of(context).secondaryText,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          _isEditingDetails
                              ? DropdownButton<String>(
                                  value: _type,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _type = newValue!;
                                    });
                                  },
                                  items: _animalTypes
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                )
                              : Text(
                                  _type,
                                  style:
                                      appTheme.of(context).bodyLarge.override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                ),
                        ],
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Owner',
                            style: appTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: appTheme.of(context).secondaryText,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          _isEditingDetails
                              ? TextField(
                                  controller: _ownerController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter owner name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                )
                              : Text(
                                  _owner,
                                  style:
                                      appTheme.of(context).bodyLarge.override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Breed',
                            style: appTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: appTheme.of(context).secondaryText,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          _isEditingDetails
                              ? TextField(
                                  controller: _breedController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter breed',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                )
                              : Text(
                                  _breed,
                                  style:
                                      appTheme.of(context).bodyLarge.override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (_isEditingDetails)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _saveChangesDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.of(context).success,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Save'),
                    ),
                    SizedBox(width: screenWidth * 0.1),
                    ElevatedButton(
                      onPressed: _cancelEditingDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.of(context).success,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

////////////////////////////////////////health overview //////////////////////////////////////////
  Widget _buildHealthOverview() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = 24.0;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          screenWidth * 0.01, 0.0, screenWidth * 0.01, 0.0),
      child: Container(
        width: screenWidth * 1.0,
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(screenWidth * 0.01,
              screenHeight * 0.01, screenWidth * 0.01, screenHeight * 0.01),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Health Overview',
                        style: appTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter Tight',
                              color: appTheme.of(context).success,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ),
                  if (!_isEditingHealth)
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: appTheme.of(context).success,
                        size: iconSize,
                      ),
                      onPressed: _toggleEditingHealth,
                    ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight',
                        style: appTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: appTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                      Row(
                        children: [
                          _isEditingHealth
                              ? Container(
                                  width: screenWidth * 0.15,
                                  child: TextField(
                                    controller: _weightController,
                                    decoration: InputDecoration(
                                      hintText: '',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      errorText: _weightError.isNotEmpty
                                          ? _weightError
                                          : null,
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                  ),
                                )
                              : Text(
                                  _weight,
                                  style: appTheme
                                      .of(context)
                                      .headlineSmall
                                      .override(
                                        fontFamily: 'Inter Tight',
                                        letterSpacing: 0.0,
                                      ),
                                ),
                          Text(
                            ' kg',
                            style: appTheme.of(context).headlineSmall.override(
                                  fontFamily: 'Inter Tight',
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Height',
                        style: appTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: appTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                      Row(
                        children: [
                          _isEditingHealth
                              ? Container(
                                  width: screenWidth * 0.15,
                                  child: TextField(
                                    controller: _heightController,
                                    decoration: InputDecoration(
                                      hintText: '',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      errorText: _heightError.isNotEmpty
                                          ? _heightError
                                          : null,
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                  ),
                                )
                              : Text(
                                  _height,
                                  style: appTheme
                                      .of(context)
                                      .headlineSmall
                                      .override(
                                        fontFamily: 'Inter Tight',
                                        letterSpacing: 0.0,
                                      ),
                                ),
                          Text(
                            ' cm',
                            style: appTheme.of(context).headlineSmall.override(
                                  fontFamily: 'Inter Tight',
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Age',
                        style: appTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: appTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                      Row(
                        children: [
                          _isEditingHealth
                              ? Container(
                                  width: screenWidth * 0.15,
                                  child: TextField(
                                    controller: _ageController,
                                    decoration: InputDecoration(
                                      hintText: '',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      errorText: _ageError.isNotEmpty
                                          ? _ageError
                                          : null,
                                    ),
                                    readOnly: true,
                                    onTap: () => _selectBirthDate(context),
                                  ),
                                )
                              : Text(
                                  _age,
                                  style: appTheme
                                      .of(context)
                                      .headlineSmall
                                      .override(
                                        fontFamily: 'Inter Tight',
                                        letterSpacing: 0.0,
                                      ),
                                ),
                          Text(
                            ' yrs',
                            style: appTheme.of(context).headlineSmall.override(
                                  fontFamily: 'Inter Tight',
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (_isEditingHealth)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _saveChangesHealth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.of(context).success,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Save'),
                    ),
                    SizedBox(width: screenWidth * 0.1),
                    ElevatedButton(
                      onPressed: _cancelEditingHealth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.of(context).success,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

////////////////////////////////////////special notes //////////////////////////////////////////
  Widget _buildSpecialNotes() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = 24.0;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          screenWidth * 0.01, 0.0, screenWidth * 0.01, 0.0),
      child: Container(
        width: screenWidth * 1.0,
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(screenWidth * 0.01,
              screenHeight * 0.01, screenWidth * 0.01, screenHeight * 0.01),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Special Notes',
                        style: appTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter Tight',
                              color: appTheme.of(context).success,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ),
                  if (!_isAddingNote)
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: appTheme.of(context).success,
                        size: iconSize,
                      ),
                      onPressed: () => _toggleAddItem(
                          _isAddingNote, (value) => _isAddingNote = value),
                    ),
                ],
              ),
              if (_isAddingNote)
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      screenWidth * 0.01, 0.0, screenWidth * 0.01, 0.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'Enter a special note',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          errorText:
                              _isNoteEmpty ? 'Note cannot be empty' : null,
                        ),
                                             maxLines: null, // Allows the TextField to grow dynamically
                    minLines: 1,
                        onChanged: (text) {
                          setState(() {
                            _isNoteEmpty = text.isEmpty;
                            _isNoteFound = _pet.specialNotes.any(
                              (note) =>
                                  note['text'] == text &&
                                  note['style'] == _selectedStyle,
                            );
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        children: [
                          Text(
                            'Note Type:',
                            style: appTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Inter',
                                  letterSpacing: 0.0,
                                ),
                          ),
                          SizedBox(width: 8.0),
                          DropdownButton<String>(
                            value: _selectedStyle,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStyle = newValue!;
                                _isNoteFound = _pet.specialNotes.any(
                                  (note) =>
                                      note['text'] == _noteController.text &&
                                      note['style'] == _selectedStyle,
                                );
                              });
                            },
                            items: <String>[
                              'Allergies',
                              'Medical Conditions',
                              'Behavioral Notes'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (_noteController.text.isEmpty) {
                                setState(() {
                                  _isNoteEmpty = true;
                                });
                                return;
                              }

                              bool noteExists = _pet.specialNotes.any(
                                (note) =>
                                    note['text'] == _noteController.text &&
                                    note['style'] == _selectedStyle,
                              );

                              if (noteExists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Note already exists!',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Add the note and update Firestore
                              setState(() {
                                _isNoteEmpty = false;
                                _pet.specialNotes.add({
                                  'text': _noteController.text,
                                  'style': _selectedStyle,
                                });
                                _noteController.clear();
                                _isAddingNote = false;
                              });

                              // Save to Firestore
                              try {
                                final success = await _pet.updateToFirestore();
                                if (success) {
                                  logger.d(
                                      'Note added and Firestore updated successfully.');
                                } else {
                                  logger.e('Failed to update Firestore.');
                                }
                              } catch (e) {
                                logger.e('Error updating Firestore: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appTheme.of(context).success,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Add Note'),
                          ),
                          ElevatedButton(
                            onPressed: () => _cancelAddItem(_noteController,
                                (value) => _isAddingNote = value),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appTheme.of(context).success,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              _pet.specialNotes.isEmpty
                  ? Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.1),
                      child: Text(
                        'No special notes yet.',
                        style: appTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              fontSize: 15.5,
                              letterSpacing: 0.0,
                            ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.max,
                      children: _pet.specialNotes.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, String> note = entry.value;
                        return Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0, 0, 0, screenHeight * 0.01),
                          child: Dismissible(
                            key: Key(note['text']!),
                            direction: DismissDirection.horizontal,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                return await _confirmDeleteItem(
                                    index, _pet.specialNotes, 'note');
                              } else if (direction ==
                                  DismissDirection.startToEnd) {
                                await _editNote(index);
                                return false;
                              }
                              return false;
                            },
                            onDismissed: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                setState(() {
                                  _pet.specialNotes.removeAt(index);
                                });

                                // Update Firestore
                                try {
                                  final success =
                                      await _pet.updateToFirestore();
                                  if (success) {
                                    logger.d(
                                        'Note deleted and Firestore updated successfully.');
                                  } else {
                                    logger.e(
                                        'Failed to update Firestore after deletion.');
                                  }
                                } catch (e) {
                                  logger.e(
                                      'Error updating Firestore after deletion: $e');
                                }
                              }
                            },
                            background: Container(
                              color: Colors.grey,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                              ),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: note['style'] == 'Medical Conditions'
                                    ? Color(0xFFE3F2FD)
                                    : note['style'] == 'Allergies'
                                        ? Color(0xFFFFEBEE)
                                        : Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                  screenWidth * 0.05,
                                  screenHeight * 0.01,
                                  screenWidth * 0.05,
                                  screenHeight * 0.01,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            note['text']!,
                                            style: appTheme
                                                .of(context)
                                                .bodyLarge
                                                .override(
                                                  fontFamily: 'Inter',
                                                  color: note['style'] ==
                                                          'Medical Conditions'
                                                      ? Colors.blue
                                                      : note['style'] ==
                                                              'Allergies'
                                                          ? Color(0xFF962433)
                                                          : Colors.orange,
                                                  letterSpacing: 0.0,
                                                ),
                                            overflow: TextOverflow.visible,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      note['style'] == 'Medical Conditions'
                                          ? Icons.medical_services
                                          : note['style'] == 'Allergies'
                                              ? Icons.block
                                              : Icons.warning,
                                      color:
                                          note['style'] == 'Medical Conditions'
                                              ? Colors.blue
                                              : note['style'] == 'Allergies'
                                                  ? Color(0xFF962433)
                                                  : Colors.orange,
                                      size: iconSize,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

////////////////////////////////////////last activities //////////////////////////////////////////
  Widget _buildLastActivities() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = 24.0;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          screenWidth * 0.01, 0.0, screenWidth * 0.01, 0.0),
      child: Container(
        width: screenWidth * 1.0,
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(screenWidth * 0.01,
              screenHeight * 0.01, screenWidth * 0.01, screenHeight * 0.01),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Last Activities',
                        style: appTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter Tight',
                              color: appTheme.of(context).success,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ),
                  if (!_isAddingActivity)
                    Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: appTheme.of(context).success,
                          size: iconSize,
                        ),
                        onPressed: () => _toggleAddItem(_isAddingActivity,
                            (value) => _isAddingActivity = value),
                      ),
                    ),
                ],
              ),
              if (_isAddingActivity)
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      screenWidth * 0.01,
                      screenHeight * 0.01,
                      screenWidth * 0.01,
                      screenHeight * 0.01),
                  child: Column(
                    children: [
                      TextField(
                        controller: _activityController,
                        decoration: InputDecoration(
                          hintText: 'Enter an activity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          errorText: _isActivityEmpty
                              ? 'Activity cannot be empty'
                              : _isActivityFound
                                  ? 'Activity already exists'
                                  : null,
                        ),
                                             maxLines: null, // Allows the TextField to grow dynamically
                    minLines: 1,
                        onChanged: (text) {
                          setState(() {
                            _isActivityEmpty = text.isEmpty;
                            _isActivityFound =
                                _pet.lastActivities.contains(text);
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (_activityController.text.isEmpty) {
                                setState(() {
                                  _isActivityEmpty = true;
                                });
                                return;
                              }

                              bool activityExists = _pet.lastActivities
                                  .contains(_activityController.text);

                              if (activityExists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Activity already exists!',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _isActivityEmpty = false;
                                _isActivityFound = false;
                                _pet.lastActivities
                                    .add(_activityController.text);
                                _activityController.clear();
                                _isAddingActivity = false;
                              });

                              try {
                                final success = await _pet.updateToFirestore();
                                if (success) {
                                  logger.d(
                                      'Activity added and Firestore updated successfully.');
                                } else {
                                  logger.e('Failed to update Firestore.');
                                }
                              } catch (e) {
                                logger.e('Error updating Firestore: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appTheme.of(context).success,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Add Activity'),
                          ),
                          ElevatedButton(
                            onPressed: () => _cancelAddItem(_activityController,
                                (value) => _isAddingActivity = value),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appTheme.of(context).success,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              SizedBox(height: screenHeight * 0.01),
              _pet.lastActivities.isEmpty
                  ? Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.1),
                      child: Text(
                        'No recent activities recorded.',
                        style: appTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              fontSize: 15.5,
                              letterSpacing: 0.0,
                            ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.max,
                      children:
                          _pet.lastActivities.asMap().entries.map((entry) {
                        int index = entry.key;
                        String activity = entry.value;
                        return Column(
                          children: [
                            Dismissible(
                              key: Key(activity),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  return await _confirmDeleteItem(
                                      index, _pet.lastActivities, 'activity');
                                } else if (direction ==
                                    DismissDirection.startToEnd) {
                                  await _editActivity(index);
                                  return false;
                                }
                                return false;
                              },
                              onDismissed: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  setState(() {
                                    _pet.lastActivities.removeAt(index);
                                  });

                                  try {
                                    final success =
                                        await _pet.updateToFirestore();
                                    if (success) {
                                      logger.d(
                                          'Activity deleted and Firestore updated successfully.');
                                    } else {
                                      logger.e(
                                          'Failed to update Firestore after deletion.');
                                    }
                                  } catch (e) {
                                    logger.e(
                                        'Error updating Firestore after deletion: $e');
                                  }
                                }
                              },
                              background: Container(
                                color: Colors.grey,
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    screenWidth * 0.01,
                                    0.0,
                                    screenWidth * 0.01,
                                    0.0),
                                child: Container(
                                  width: screenWidth * 1.0,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            activity,
                                            style: appTheme
                                                .of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Inter',
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                          ],
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackGround() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: screenWidth * 1.0,
      height: screenHeight * 1.0,
      child: Stack(
        children: [
          Container(
            width: screenWidth * 1.0,
            height: screenHeight * 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.blue],
                stops: [0.0, 1.0],
                begin: AlignmentDirectional(0.0, -1.0),
                end: AlignmentDirectional(0, 1.0),
              ),
            ),
          ),
          Container(
            width: screenWidth * 1.0,
            height: screenHeight * 1.0,
            decoration: BoxDecoration(
              color: Color(0x66000000),
            ),
          ),
        ],
      ),
    );
  }

////////////////////////end of last activities //////////////////////////////////////////////////
  Widget _buildProfilePicture(double screenWidth, double screenHeight) {
    return Center(
      child: Container(
        height: 250.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60.0),
              ),
              child: Container(
                width: 120.0,
                height: 120.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60.0),
                  border: Border.all(
                    color: Colors.white,
                    width: 3.0,
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Container(
                            width: screenWidth * 0.8,
                            height: screenHeight * 0.5,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : (imageUrl != null && imageUrl!.isNotEmpty)
                                        ? NetworkImage(imageUrl!)
                                        : AssetImage(
                                                'assets/images/PetProfilePicture.png')
                                            as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                    logger.d('Profile picture $imageUrl');
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImage != null
                        ? FileImage(
                            _profileImage!) // Use the locally picked image
                        : (imageUrl != null &&
                                imageUrl!
                                    .isNotEmpty) // Check if the Pet object has an image URL
                            ? NetworkImage(_pet
                                .imageUrl!) // Use the image URL from the Pet object
                            : AssetImage('assets/images/PetProfilePicture.png')
                                as ImageProvider, // Fallback to default asset
                    backgroundColor:
                        Colors.grey[200], // Optional: Add a background color
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.0),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 1.0), // Optional for spacing
              child: AutoSizeText(
                _pet.name,
                style: appTheme.of(context).headlineMedium.override(
                      fontFamily: 'Inter Tight',
                      color: Colors.white,
                      letterSpacing: 0.0,
                    ),
                maxLines: 1,
                minFontSize: 10, // Minimum font size
                maxFontSize: 24, // Maximum font size
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis if the text overflows
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AutoSizeText(
                _pet.bio,
                textAlign: TextAlign.center, // Center-align the bio text
                style: appTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter Tight',
                      color: const Color(0xFFE0E0E0),
                      fontSize: 16.0,
                      letterSpacing: 0.0,
                    ),
                maxLines: 3, // Allow up to 3 lines if the bio is longer
                minFontSize: 12,
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis only if bio overflows
              ),
            ),
          ].divide(SizedBox(height: 4.0)), // Reduce the space between elements
        ),
      ),
    );
  }

  Widget _buildFAB() {
    if (_model.choiceChipsValue == 'Schedule') {
      // Existing FAB for adding pets
      return FloatingActionButton.extended(
        onPressed: () {
          print('add pet event');
         _showAddEditEventDialog( 0, true, 'pet');
        },
        backgroundColor: const Color(0xFF249689),
        elevation: 8,
        label: Row(
          children: [
            Text(
              'Add Event',
              style: appTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    letterSpacing: 0.0,
                  ),
            ),
            Icon(
              Icons.add_rounded,
              color: appTheme.of(context).info,
              size: 24,
            ),
          ],
        ),
      );
    }
    else {
    return SizedBox.shrink(); // Return an empty widget if no condition is met
  } 
  }

}
