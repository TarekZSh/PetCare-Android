import 'package:auto_size_text/auto_size_text.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_care_app/firebase/vet_class.dart';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:pet_care_app/main_screeen_manager.dart';
import 'package:pet_care_app/screens/vet/vet_patient_list/vet_patient_list_widget.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/common/choice_chips_widget.dart';
import '/common/app_theme.dart';
import '/common/app_utils.dart';
import '/common/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'vet_profile_model.dart';
export 'vet_profile_model.dart';
import 'package:pet_care_app/screens/google_map_screen.dart';
import 'dart:io';
import 'package:pet_care_app/services/notifications_service.dart';
import '/providers/auth_provider.dart';
import '../../services/edit_profile_name_bio.dart';

class VetProfileWidget extends StatefulWidget {
  @override
  _VetProfileWidgetState createState() => _VetProfileWidgetState();
}

class _VetProfileWidgetState extends State<VetProfileWidget> {
  late VetProfileModel _model;
  late Vet _vet;
  final logger = Logger();
  String name = 'Example';
  String bio = 'Bio Example';
  String? imageUrl;
  String email = "example@example.com";
  String phone = '123-456-7890';
  String location = 'City, Country';
  double experience = -1.0;
  String degree = 'Degree';
  String university = 'University';
  String _currentView = 'Profile';
  List<String> specializations = [];
List<Map<String, dynamic>> appointments = [];

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  final TextEditingController _experienceController = TextEditingController();
  late TextEditingController _universityController;

  final List<String> _degrees = ['Bachelor', 'Master', 'Doctor', 'PhD'];

  File? _profileImage;

  //AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> predefinedSpecializations = [
    'Anesthesiology',
    'Aquatic Animals',
    'Avian (Birds)',
    'Behavioral Medicine',
    'Bovine Medicine',
    'Cardiology',
    'Canine Medicine',
    'Dentistry',
    'Dermatology',
    'Emergency and Critical Care',
    'Equine Medicine',
    'Exotics',
    'Feline Medicine',
    'Genetics and Breeding',
    'Internal Medicine',
    'Large Animals',
    'Neurology',
    'Nutrition',
    'Oncology',
    'Ophthalmology',
    'Poultry Medicine',
    'Preventive Care',
    'Radiology',
    'Rehabilitation and Sports Medicine',
    'Reptiles and Amphibians',
    'Small Animals',
    'Surgery',
    'Swine Medicine',
    'Veterinary Pathology',
    'Veterinary Pharmacology',
    'Veterinary Public Health',
    'Veterinary Toxicology',
    'Wildlife',
    'Zoo Medicine'
  ];

  void scheduleNotificationsForExistingAppointments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      final vetDoc = await FirebaseFirestore.instance.collection('vets').doc(user.uid).get();
      if (vetDoc.exists) {
        final vetData = vetDoc.data();
        if (vetData != null && vetData.containsKey('patientPetIds')) {
          for (var patientId in vetData['patientPetIds']) {
            final patientDoc = await FirebaseFirestore.instance.collection('pets').doc(patientId).get();
            if (patientDoc.exists) {
              final patientData = patientDoc.data();
              if (patientData != null && (patientData.containsKey('vetEvents'))) {
                for (var event in patientData['vetEvents']){
                  DateTime eventDate = DateTime.parse(event['date']).add(Duration(
                    hours: _parseTime(event['time']).hour,
                    minutes: _parseTime(event['time']).minute,
                  ));
                  DateTime firstNotificationTime = eventDate.subtract(Duration(minutes: 1440));
                  DateTime secondNotificationTime = eventDate.subtract(Duration(minutes: 60));
                  DateTime thirdNotificationTime = eventDate.subtract(Duration(minutes: 5));

                  if (firstNotificationTime.isAfter(DateTime.now())) {
                    NotificationService.scheduleNotification(
                      id: firstNotificationTime.millisecondsSinceEpoch ~/ 1000,
                      title: event['title'] ?? '',
                      body: "Don't miss your event",
                      notificationTime: firstNotificationTime,
                    );
                  }
                  if (secondNotificationTime.isAfter(DateTime.now())) {
                    NotificationService.scheduleNotification(
                      id: secondNotificationTime.millisecondsSinceEpoch ~/ 1000,
                      title: event['title'] ?? '',
                      body: "Don't miss your event",
                      notificationTime: secondNotificationTime,
                    );
                  }
                  if (thirdNotificationTime.isAfter(DateTime.now())) {
                    NotificationService.scheduleNotification(
                      id: thirdNotificationTime.millisecondsSinceEpoch ~/ 1000,
                      title: event['title'] ?? '',
                      body: "Don't miss your event",
                      notificationTime: thirdNotificationTime,
                    );
                  }
                 }
              }
            }
          }
        }
      }
    }
  }
  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VetProfileModel());
    _nameController = TextEditingController(text: name);
    _bioController = TextEditingController(text: bio);
    emailController = TextEditingController(text: email);
    phoneController = TextEditingController(text: phone);
    addressController = TextEditingController(text: location);
    _universityController = TextEditingController(text: university);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _vet = authProvider.vet!;

    email = _vet.email;
    emailController.text = email;
    phone = _vet.phone;
    phoneController.text = phone;
    location = _vet.location;
    addressController.text = location;
    experience = _vet.yearsOfExperience;
    _experienceController.text = experience.toString();
    degree = _vet.degree;
    university = _vet.university;
    _universityController.text = university;
    name = _vet.name;
    _nameController.text = name;
    bio = _vet.bio;
    _bioController.text = bio;
    imageUrl = _vet.imageUrl;
    specializations = _vet.specializations;
    _currentView = _model.choiceChipsValue ?? 'Profile';

     appointments = [];
    for (var pet in _vet.patients) {
    appointments.addAll(pet.vetEvents);
  }


    scheduleNotificationsForExistingAppointments();
  }
  
  @override
  void dispose() {
    _model.dispose();
    _experienceController.dispose();
    _universityController.dispose();
    _bioController.dispose();
    _nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  ///////// logout /////////
  Future<void> _handleLogout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await NotificationService.cancelAllNotifications();
      await authProvider.signOut();
      logger.d('Logout successful');
      // Navigate to the login screen or any other appropriate screen
      context.go('/login');
    } catch (e) {
      logger.e('Error logging out: $e');
      logger.e('khokkkkkkkka');
      // Optionally, show an error message to the user
    }
  }

///////specializations
  //List<String> lastActivities = [];
  bool _isAddingSpecialization = false;
  String?
      _selectedSpecialization; // Tracks the currently selected specialization

  String _errorMessageSpecialization = '';
  final List<Color> predefinedColors = [
    Color(0xFFE6E6FA), // Lavender Purple
    Color(0xFFB0E0E6), // Powder Blue
    Color(0xFFF5FFFA), // Mint Cream
    Color(0xFFFFD1DC), // Pale Pink
    Color(0xFFFFDAB9), // Peach Puff
    Color(0xFFE3F2FD), // Baby Blue
    Color(0xFFDCD0FF), // Soft Lilac
    Color(0xFFDFFFE2), // Sea Mist Green
    Color(0xFFFFFACD), // Light Lemon Yellow
    Color(0xFFF0F8FF), // Ice White
  ];
  Map<String, Color> specializationColors = {};

  void _addSpecialization(String? specialization) async {
    if (specialization == null || specialization.isEmpty) {
      setState(() {
        _errorMessageSpecialization = 'Please select a specialization.';
      });
    } else if (specializations.contains(specialization)) {
      setState(() {
        _errorMessageSpecialization = 'Specialization already added.';
      });
    } else {
      setState(() {
        specializations.add(specialization);
        _errorMessageSpecialization = '';
        _selectedSpecialization = null; // Reset selected specialization
        specializationColors[specialization] =
            predefinedColors[specializations.length % predefinedColors.length];
      });

      // Add specialization to Firestore
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('vets')
              .doc(user.uid)
              .update({
            'specializations': FieldValue.arrayUnion([specialization]),
          });
          logger.d('Specialization added to Firestore successfully');
        }
      } catch (e) {
        logger.e('Error adding specialization to Firestore: $e');
      }
    }
  }

  void _toggleAddItem(bool isAdding, Function(bool) setStateCallback) {
    setState(() {
      setStateCallback(!isAdding);
    });
  }

  void _deleteItem(int index, List<String> list) {
    setState(() {
      list.removeAt(index);
    });
  }

  Future<bool?> _confirmDeleteItem(int index, List<String> list) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this specialization?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: appTheme.of(context).success,
                  foregroundColor: Colors.white),
              child: Text('No'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: appTheme.of(context).success,
                  foregroundColor: Colors.white),
              child: Text('Yes'),
              onPressed: () async {
                String specializationToDelete = list[index];
                _deleteItem(index, list);
                Navigator.of(context).pop(true);

                // Delete specialization from Firestore
                try {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  final user = authProvider.user;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('vets')
                        .doc(user.uid)
                        .update({
                      'specializations':
                          FieldValue.arrayRemove([specializationToDelete]),
                    });
                    logger.d(
                        'Specialization removed from Firestore successfully');
                  }
                } catch (e) {
                  logger.e('Error removing specialization from Firestore: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

//calc experince////
  DateTime? _startDate;

  void _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _startDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        helpText: "select you starting date");
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _experienceController.text =
            '${_calculateExperience(picked).toStringAsFixed(2)} years of experience';
      });
    }
  }

  double _calculateExperience(DateTime startDate) {
    DateTime today = DateTime.now();
    int years = today.year - startDate.year;
    int months = today.month - startDate.month;
    if (months < 0 || (months == 0 && today.day < startDate.day)) {
      years--;
      months += 12;
    }
    double experience = years + (months / 100);
    return experience;
  }


////////////////////////////mays//////////////////

void updateVetAppointments(){
  setState(() {
  appointments = [];
    for (var pet in _vet.patients) {
      appointments.addAll(pet.vetEvents);
    }
  });
}
void addAppointment(Map<String, dynamic> appointment) {
      final petId = appointment['petId'];
      final petIndex = _vet.patients.indexWhere((pet) => pet.id == petId);  
      setState(() {
         _vet.patients[petIndex].vetEvents.add(appointment); // Notify listeners about the change
        _vet.patients[petIndex].saveToFirestore();
        _vet.saveToFirestore();
        updateVetAppointments();
      });
  }

bool areEventsEqual(Map<String, dynamic> event1, Map<String, dynamic> event2) {
  return event1['date'] == event2['date'] &&
         event1['doctorName'] == event2['doctorName'] &&
         event1['time'] == event2['time'] &&
         event1['title'] == event2['title'];
}

  void updateAppointment(int index,Map<String, dynamic> appointment) async {
    _vet = (await Vet.fetchFromFirestore(_vet.id))!;
    final appointmentToFind = appointments[index];
    logger.e('The appointment to find is $appointmentToFind');
    final oldPetId = appointmentToFind['petId'];
    final newPetId = appointment['petId'];
    final oldPetIndex = _vet.patients.indexWhere((pet) => pet.id == oldPetId);
    final newPetIndex = _vet.patients.indexWhere((pet) => pet.id == newPetId);
    logger.e('The old pet index is $oldPetIndex The new pet index is $newPetIndex');
    _vet.patients[oldPetIndex] = (await Pet.fetchFromFirestore(oldPetId))!;
    _vet.patients[newPetIndex] = (await Pet.fetchFromFirestore(newPetId))!;
    final oldAppointmentIndex = _vet.patients[oldPetIndex].vetEvents.indexWhere((event) =>  areEventsEqual(event, appointmentToFind));
      setState(() {
      _vet.patients[oldPetIndex].vetEvents.removeAt(oldAppointmentIndex); // Notify listeners about the change
      _vet.patients[newPetIndex].vetEvents.add(appointment);
      _vet.patients[oldPetIndex].saveToFirestore();
      _vet.patients[newPetIndex].saveToFirestore();
      _vet.saveToFirestore();
      updateVetAppointments();
      });
  }

  void deleteAppointment(int index) {
    final appointmentToFind = appointments[index];
    final petId = appointmentToFind['petId'];
    final petIndex =  _vet.patients.indexWhere((pet) => pet.id == petId);
    final eventIndex =  _vet.patients[petIndex].vetEvents.indexWhere((event) => areEventsEqual(event, appointmentToFind));
      setState(() {
        _vet.patients[petIndex].vetEvents.removeAt(eventIndex); // Notify listeners about the change
        _vet.patients[petIndex].saveToFirestore();
        updateVetAppointments();
      });
  }
  
Future<bool?> _confirmDeleteAppointment(Map<String, dynamic> appointmentDetails, int index,{bool isDoctor = false, done = false}) async {
    return showDialog<bool>(
       context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(done ? 'Confirm Completion' : 'Confirm Deletion'),
              content: Text(done
                  ? 'Please confirm that the scheduled appointment is finished.'
                  : 'Are you sure you want to delete this appointment?'),
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
                    deleteAppointment(index);
                      print('Done button pressed');
                    
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ;
  }

TimeOfDay _parseTime(String time) {
  try {
    final format = DateFormat.Hm(); // or use DateFormat.Hm() for 24-hour format
    final dateTime = format.parse(time);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  } catch (e) {
    // Handle the exception if the format is not correct
    print('Error parsing time: $e');
    return TimeOfDay(hour: 0, minute: 0); // Return a default value or handle it as needed
  }
}


  void _showAddEditAppointmentDialog( int index, bool isAdding, String type) {
    String? petId = isAdding ? null : appointments[index]['petId'];
    Pet? selectedPet = isAdding ? null : _vet.patients.firstWhere((pet) => pet.id == petId);
    final titleController = TextEditingController(text: isAdding ? '' : appointments[index]['title']);
    DateTime? selectedDate = isAdding ? null : DateTime.parse(appointments[index]['date']);
    TimeOfDay? selectedTime = isAdding ? null : _parseTime(appointments[index]['time']);
    DateTime? oldDate = selectedDate;
    TimeOfDay? oldTime = selectedTime;
    
   showDialog(
  context: context,
  builder: (context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(isAdding ? "Add New Appointment" : "Edit Appointment"),
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
                    if (type != 'pet')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Pet Name",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(width: 4), // Add space between the texts
                              Text(
                                "*",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          DropdownButtonFormField<Pet>(
                            value: isAdding
                                ? null
                                : _vet.patients.firstWhere((pet) => pet.id == appointments[index]['petId']),
                            items: _vet.patients.map((pet) {
                              return DropdownMenuItem<Pet>(
                                value: pet,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: pet.imageUrl != null
                                          ? NetworkImage(pet.imageUrl!)
                                          : AssetImage('assets/images/PetProfilePicture.png')
                                              as ImageProvider,
                                    ),
                                    SizedBox(width: 8),
                                    Text(pet.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (Pet? value) {
                              setState(() {
                                selectedPet = value; // Save the selected pet object
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
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
                  ],
                ),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    selectedDate == null ||
                    selectedTime == null || (!isAdding && selectedPet == null)) {
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
                
                final newAppointment = {
                  'title': titleController.text,
                  'petId': selectedPet?.id,
                  'date': selectedDate?.toIso8601String() ?? '',
                  'time': selectedTime?.format(context) ?? '',
                  'eventType': 'Health and Wellness',
                  'doctorName': _vet.name,
                  'shaverName': '',
                  'notes': '',
                };
                bool appointmentExists = appointments.any((appointment) =>
                    appointment['title'] == newAppointment['title'] &&
                    appointment['petId'] == newAppointment['petId'] &&
                    appointment['date'] == newAppointment['date'] &&
                    appointment['time'] == newAppointment['time']);

                if (appointmentExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("This appointment already exists!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (isAdding) {
                  addAppointment(newAppointment);
                } else {
                  updateAppointment(index, newAppointment);
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
                    title: newAppointment['title'] ?? '',
                    body: "don't miss your event",
                    notificationTime: firstNotificationTime,
                  );
                }
                if (secondNotificationTime.isAfter(DateTime.now())) {
                  NotificationService.scheduleNotification(
                    id: secondNotificationTime.millisecondsSinceEpoch ~/ 1000,
                    title: newAppointment['title'] ?? '',
                    body: "don't miss your event",
                    notificationTime: secondNotificationTime,
                  );
                }
                if (thirdNotificationTime.isAfter(DateTime.now())) {
                  NotificationService.scheduleNotification(
                    id: thirdNotificationTime.millisecondsSinceEpoch ~/ 1000,
                    title: newAppointment['title'] ?? '',
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
  TimeOfDay? parsedTime;
  String formattedTime = '';
  if(time != '') {
      parsedTime = _parseTime(time);
      formattedTime = parsedTime.format(context);
  }
  String formattedDate = DateFormat('MMMM dd, yyyy').format(parsedDate);
  return '$formattedDate, $formattedTime';
}

Widget buildAppointment(Map<String, dynamic> AppointmentDetails,String AppointmentType,String userTybe) {
    // Define the icon, color, and other details based on eventType
    IconData icon;
    Color iconColor;
    Color backgroundColor;
    String title;
    String petNameText;
    Pet pet = _vet.patients.firstWhere((pet) => pet.id == AppointmentDetails['petId']);

    switch (AppointmentType) {
      case 'Health and Wellness':
        icon = Icons.medical_services;
        iconColor = appTheme.of(context).success;
        backgroundColor = Color(0xFFE8F5E9);
        title = AppointmentDetails['title'];
        petNameText = 'For ${pet.name}';
        break;
      default:
        // For unknown event types, show basic ListTile
        return ListTile(
          title: Text(AppointmentDetails['title']),
          subtitle:
              Text('${pet.name} - ${AppointmentDetails['eventType']}'),
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
                  if(userTybe!='pet')
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
                       formatEventDateTime(AppointmentDetails['date'], AppointmentDetails['time'], context),
                      style: appTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            color: appTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                ],
              ),
            ),
           CircleAvatar(
              backgroundColor: appTheme.of(context).success.withOpacity(0.4),
              radius: MediaQuery.of(context).size.width * 0.05, // 10% of screen width / 2
              child: IconButton(
                onPressed: () {
                  int index = appointments.indexWhere((appointment) => appointment == AppointmentDetails);
                  _confirmDeleteAppointment(AppointmentDetails, index, isDoctor: true, done: true);
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
  
void sortAppointmentsByDateTime(List<Map<String, dynamic>> events) {
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

Widget buildAppointmentWidget(String userType) {
  print('in the func');

 sortAppointmentsByDateTime(appointments);
  // Avoid using Scaffold and Expanded if already wrapped in another layout
  return Column(
    children: [
      SizedBox(height: 16), // Add a SizedBox at the top
      appointments.isEmpty
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
                    'No Appointment Scheduled',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true,  // Prevents unbounded height error
              physics: NeverScrollableScrollPhysics(), // Avoid nested scrolling conflict
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return Column(
                  children: [
                    Dismissible(
                      key: Key(appointment['title']),
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
                          _showAddEditAppointmentDialog(index, false, 'doctor');
                          return false;
                        } else if (direction == DismissDirection.endToStart) {
                          return await _confirmDeleteAppointment(appointment, index);
                        }
                        return false;
                      },
                      child: buildAppointment(appointment, 'Health and Wellness', 'doctor'),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Add a SizedBox between each appointment
                  ],
                );
              },
            ),
    ],
  );
 }

/////////////////////////////build method//////////////////////////////
  @override
  Widget build(BuildContext context) {
    
    // DateTime eventDate = selectedDate!.add(Duration(
    //               hours: selectedTime!.hour,
    //               minutes: selectedTime!.minute,
    //             ));

                
    //             // String eventTitle = titleController.text;
    //             DateTime firstNotificationTime = eventDate.subtract(Duration(minutes: 1440));
    //             DateTime secondNotificationTime = eventDate.subtract(Duration(minutes: 60));
    //             DateTime thirdNotificationTime = eventDate.subtract(Duration(minutes: 5));

                
    //             // String eventTitle = titleController.text;
    //             // logger.f('the new ${firstNotificationTime.millisecondsSinceEpoch ~/ 1000} and the eventDate is $eventDate');
                
    //             if (firstNotificationTime.isAfter(DateTime.now())) {
    //               NotificationService.scheduleNotification(
    //                 id: firstNotificationTime.millisecondsSinceEpoch ~/ 1000,
    //                 title: newAppointment['title'] ?? '',
    //                 body: "don't miss your event",
    //                 notificationTime: firstNotificationTime,
    //               );
    //             }
    //             if (secondNotificationTime.isAfter(DateTime.now())) {
    //               NotificationService.scheduleNotification(
    //                 id: secondNotificationTime.millisecondsSinceEpoch ~/ 1000,
    //                 title: newAppointment['title'] ?? '',
    //                 body: "don't miss your event",
    //                 notificationTime: secondNotificationTime,
    //               );
    //             }
    //             if (thirdNotificationTime.isAfter(DateTime.now())) {
    //               NotificationService.scheduleNotification(
    //                 id: thirdNotificationTime.millisecondsSinceEpoch ~/ 1000,
    //                 title: newAppointment['title'] ?? '',
    //                 body: "don't miss your event",
    //                 notificationTime: thirdNotificationTime,
    //               );
    //             }
                
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: appTheme.of(context).primaryBackground,
        floatingActionButton: _buildFAB(),
        body: Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          child: Stack(
            children: [
              _buildGradientBackground(),
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditProfileHeader(),
                      _buildProfileHeader(),
                      Material(
                        color: Colors.transparent,
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Container(
                          width: MediaQuery.sizeOf(context).width * 1.0,
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
                                _buildChoiceChip(),
                                if (_currentView == 'Profile')
                                  _buildProfileOverview()
                                else if (_currentView == 'Patient List')
                                  _buildPatientList()
                                else if (_currentView == 'Appointments')
                                  _buildAppointments(),
                              ].divide(SizedBox(height: 20.0)),
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 24.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOverview() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContactInfo(),
          _buildProffesionalInfo(),
          _buildSpecializationSection()
        ].divide(SizedBox(height: 16.0)));
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

  Widget _buildEditProfileHeader() {
    int iconSize = 24;
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        /*   Padding(
          padding: EdgeInsets.only(top: 20), // Adjust the value as needed
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
            logger.d('IconButton pressed ...');
          },
          ),
        ),*/
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
          child: PopupMenuButton<String>(
            onSelected: (String result) async {
              if (result == 'Edit') {
                if (name == 'Example') {
                  _nameController.clear();
                }
                if (bio == 'Bio Example') {
                  _bioController.clear();
                }

                // Temporary variables to handle changes
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
      logger.d('I am in the set state');
      _profileImage = imageFile;
      imageUrl = newImageUrl;
    });
  },
  () {
    // Handle image deletion
    setState(() {
      logger.d('no iam here');
      _profileImage = null;
      imageUrl = '';
      logger.d('the image url after deleting is $imageUrl');
    });
  },
  tybe: 'doctor',
).then((bool result) {
  // Check the result of the dialog
  if (result) {
    // If Save was clicked, update local state immediately
    setState(() {
      name = _nameController.text;
      bio = _bioController.text;
      logger.d('the old image is $imageUrl');
      imageUrl = (_profileImage == null && imageUrl == '') ? null : imageUrl;// Temporary update
      logger.d('The new image is $_profileImage');
      logger.d('The new image URL is $imageUrl');
      _vet.imageUrl = imageUrl; 
    });

    // Perform Firebase and Firestore updates asynchronously
    Future.microtask(() async {
        // Update the Vet object with new values
        _vet.name = name;
        _vet.bio = bio;
        _vet.imageUrl = imageUrl;
        logger.d('The vet image URL is ${_vet.imageUrl}');

        logger.d('error here');

        // Save changes to Firestore
        await _vet.saveToFirestore();
        logger.d('Vet profile updated in Firestore');

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

              } else if (result == 'Logout') {
                logger.d('Logout selected');
                _handleLogout();
              } else {
                logger.d('Info selected');
                showAboutDialog(context: context);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'Info',
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.black),
                    SizedBox(width: 8.0),
                    Text('Info'),
                    // IconButton(
                    // icon: const Icon(Icons.info , color: Colors.black),
                    // onPressed: () {
                    // showAboutDialog(context: context);
                    // }
                    // ),
                    // SizedBox(width: 8.0),
                    // Text('Info'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.black),
                    SizedBox(width: 8.0),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black),
                    SizedBox(width: 8.0),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            icon: Padding(
              padding: EdgeInsets.only(top: 35), // Adjust the value as needed
              child: Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x33FFFFFF) // White transparent circle
                    ),
                width:
                    iconSize * 1.5, // Increase the width to enlarge the circle
                height:
                    iconSize * 1.5, // Increase the height to enlarge the circle
                child: Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Container(
        height: 250,
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
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.5,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : (imageUrl != null && imageUrl!.isNotEmpty)
                                        ? NetworkImage(imageUrl!)
                                        : AssetImage(
                                                'assets/images/vetProfile.png')
                                            as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (imageUrl != null && imageUrl!.isNotEmpty)
                            ? NetworkImage(imageUrl!)
                            : AssetImage('assets/images/vetProfile.png')
                                as ImageProvider,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.0),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 1.0), // Optional for spacing
              child: AutoSizeText(
                'Dr. $name',
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
            Center(
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 0.0), // Optional for spacing
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AutoSizeText(
          bio,
          style: appTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter Tight',
                color: Color(0xFFE0E0E0),
                letterSpacing: 0.0,
              ),
          maxLines: 3, // Allow up to 3 lines if the bio is longer
          minFontSize: 16,
          overflow: TextOverflow.ellipsis, // Add ellipsis only if bio overflows
          textAlign: TextAlign.center, // Center the text
        ),
      ],
    ),
  ),
),
          ].divide(SizedBox(height: 4.0)), // Reduce the space between elements
        ),
      ),
    );
  }

  Widget _buildChoiceChip() {
    return appChoiceChips(
      options: [
        ChipData('Profile'),
        ChipData('Patient List'),
        ChipData('Appointments')
      ],
      onChanged: (val) {
        setState(() {
          _model.choiceChipsValue = val?.firstOrNull;
        });
        if (_model.choiceChipsValue == 'Profile') {
          _currentView = 'Profile';
        } else if (_model.choiceChipsValue == 'Patient List') {
          // Navigate to Patient List screen
          //context.go('/patientList');
          _currentView = 'Patient List';
        } else if (_model.choiceChipsValue == 'Appointments') {
           _currentView = 'Appointments';
        }
      },
      selectedChipStyle: ChipStyle(
        backgroundColor: appTheme.of(context).success,
        textStyle: appTheme.of(context).bodyMedium.override(
              fontFamily: 'Inter',
              color: Colors.white,
              letterSpacing: 0.0,
            ),
        iconColor: appTheme.of(context).primaryText,
        iconSize: 24,
        elevation: 0.0,
        borderRadius: BorderRadius.circular(25.0),
      ),
      unselectedChipStyle: ChipStyle(
        backgroundColor: Color(0xFFF5F5F5),
        textStyle: appTheme.of(context).bodySmall.override(
              fontFamily: 'Inter',
              color: appTheme.of(context).secondaryText,
              letterSpacing: 0.0,
            ),
        iconColor: appTheme.of(context).primaryText,
        iconSize: 24,
        elevation: 0.0,
        borderRadius: BorderRadius.circular(25.0),
      ),
      chipSpacing: 12.0,
      rowSpacing: 8.0,
      multiselect: false,
      initialized: _model.choiceChipsValue != null,
      alignment: WrapAlignment.start,
      controller: _model.choiceChipsValueController ??=
          FormFieldController<List<String>>(
        ['Profile'],
      ),
      wrapped: true,
    );
  }

  Widget _buildContactInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          screenWidth * 0.01, 0.0, screenWidth * 0.01, 0.0),
      child: Stack(
        children: [
          Container(
            width: screenWidth * 1.0,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(screenWidth * 0.03,
                  screenHeight * 0.03, screenWidth * 0.03, screenHeight * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.05),
                      child: Text(
                        'Contact Information',
                        style: appTheme.of(context).titleMedium.override(
                              fontFamily: 'Inter Tight',
                              color: appTheme.of(context).success,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontSize: 25.0,
                            ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.email,
                        color: appTheme.of(context).success,
                        size: 20.0,
                      ),
                      Expanded(
                        child: Text(
                          email,
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.phone,
                        color: appTheme.of(context).success,
                        size: 20.0,
                      ),
                      Expanded(
                        child: Text(
                          phone,
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: appTheme.of(context).success,
                        size: 20.0,
                      ),
                      Expanded(
                        child: Text(
                          location,
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
            ),
          ),
          Positioned(
            top: 8.0,
            right: 8.0,
            child: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                String oldEmail = emailController.text;
                String oldPhone = phoneController.text;
                String oldLocation = addressController.text;
                if (email == "example@example.com") {
                  emailController.clear();
                }
                if (phone == '123-456-7890') {
                  phoneController.clear();
                }
                if (location == 'City, Country') {
                  addressController.clear();
                }

              showDialog(
  context: context,
  builder: (BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
    return AlertDialog(
      title: Text('Edit Details'),
      content: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidateMode,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    suffixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _autoValidateMode = AutovalidateMode.onUserInteraction;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    suffixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    final RegExp phoneRegex = RegExp(r'^[0-9+*#]+$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                    if (value.length > 15) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _autoValidateMode = AutovalidateMode.onUserInteraction;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  readOnly: true,
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    suffixIcon: Icon(Icons.place),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _autoValidateMode = AutovalidateMode.onUserInteraction;
                    });
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoogleMapScreen(
                          onPlaceSelected: (selectedLocation, theLocation) {
                            setState(() {
                              location = theLocation;
                              addressController.text = theLocation;
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            emailController.text = oldEmail;
            phoneController.text = oldPhone;
            addressController.text = oldLocation;
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              setState(() {
                email = emailController.text;
                phone = phoneController.text;
                location = addressController.text;
              });

              // Update the relevant data in Firestore
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final user = authProvider.user;
              if (user != null) {
                FirebaseFirestore.instance
                    .collection('vets')
                    .doc(user.uid)
                    .update({
                  'email': email,
                  'phone': phone,
                  'location': location,
                }).then((_) {
                  logger.d('Contact information updated successfully');
                }).catchError((error) {
                  logger.d('Failed to update contact information: $error');
                });
              }
              Navigator.of(context).pop();
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  },
);

              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProffesionalInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          screenWidth * 0.01, 0.0, screenWidth * 0.01, 0.0),
      child: Stack(
        children: [
          Container(
            width: screenWidth * 1.0,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(screenWidth * 0.03,
                  screenHeight * 0.03, screenWidth * 0.03, screenHeight * 0.03),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        right: screenWidth * 0.09), // Move it a little bit left
                    child: Center(
                      child: Text(
                        'Professional Info',
                        style: appTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter Tight',
                              color: appTheme.of(context).success,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontSize: 24.0, // Set font size to 24
                            ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.medical_services,
                        color: appTheme.of(context).success,
                        size: 24.0,
                      ),
                      Expanded(
                        child: Text(
                          // experience.isNotEmpty
                          //     ? experience.toString()
                          //     : 'Tap edit to enter your starting date',
                          '$experience years of experience',
                          textAlign: TextAlign.left,
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                color: appTheme.of(context).primaryText,
                                // experience
                                //         .isNotEmpty
                                //     ? appTheme
                                //         .of(
                                //             context)
                                //         .primaryText
                                //     : Colors
                                //         .grey, // Hint text color
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                    ].divide(SizedBox(width: 12.0)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.school,
                        color: appTheme.of(context).success,
                        size: 24.0,
                      ),
                      Expanded(
                        child: Text(
                          degree.isNotEmpty
                              ? '$degree, $university'
                              : 'Tap edit to enter your degree and university',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                color: degree.isNotEmpty
                                    ? appTheme.of(context).primaryText
                                    : Colors.grey, // Hint text color
                                letterSpacing: 0.0,
                              ),
                        ),
                      )
                    ].divide(SizedBox(width: 12.0)),
                  ),
                ].divide(SizedBox(height: 12.0)),
              ),
            ),
          ),
          Positioned(
            top: 8.0,
            right: 8.0,
            child: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                double oldExperience = experience;
                //String oldEducation = education;
                String oldDegree = degree;
                String oldUniversity = _universityController.text;

                _experienceController.text =
                    // experience
                    //         .isEmpty ||
                    experience == -1.0 ? '' : '$experience years of experience';
                _universityController.text = _universityController.text.isEmpty
                    ? ''
                    : _universityController.text;

              showDialog(
  context: context,
  builder: (BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    return AlertDialog(
      title: Text('Edit Details'),
      content: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _experienceController,
                        decoration: InputDecoration(
                          labelText: 'Experience',
                          hintText: 'Enter your starting date',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          _selectStartDate(context);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty || value == 0.00) {
                            return 'Please enter your starting date';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        _selectStartDate(context);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: degree.isEmpty ? null : degree,
                  hint: Text('Select Degree'),
                  onChanged: (String? newValue) {
                    setState(() {
                      degree = newValue!;
                    });
                  },
                  items: _degrees.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Degree',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your degree.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _universityController,
                  decoration: InputDecoration(
                    labelText: 'University',
                    hintText: 'Enter university name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your university name.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              experience = oldExperience;
              degree = oldDegree;
              university = oldUniversity;
            });
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              setState(() {
                experience = double.tryParse(
                        _experienceController.text.split(' ')[0]) ??
                    0.0; //////////// experienceError
                university = _universityController.text;
              });

              // Update the relevant data in Firestore
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final user = authProvider.user;
              if (user != null) {
                FirebaseFirestore.instance
                    .collection('vets')
                    .doc(user.uid)
                    .update({
                  'yearsOfExperience': experience,
                  'degree': degree,
                  'university': _universityController.text,
                }).then((_) {
                  logger.d('Professional information updated successfully');
                }).catchError((error) {
                  logger.d(
                      'Failed to update professional information: $error');
                });
              }
              Navigator.of(context).pop();
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  },
);

              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
          padding: EdgeInsetsDirectional.fromSTEB(
              screenWidth * 0.01, screenHeight * 0.01, screenWidth * 0.01, 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Specializations',
                        style: appTheme.of(context).titleMedium.override(
                              fontFamily: 'Inter Tight',
                              color: appTheme.of(context).success,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontSize: 24.0,
                            ),
                      ),
                    ),
                  ),
                  if (!_isAddingSpecialization)
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: appTheme.of(context).success,
                        size: 24,
                      ),
                      onPressed: () => _toggleAddItem(_isAddingSpecialization,
                          (value) => _isAddingSpecialization = value),
                    ),
                ],
              ),
              if (_isAddingSpecialization)
                Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedSpecialization,
                        hint: Text('Select a specialization'),
                        items: predefinedSpecializations
                            .map((specialization) => DropdownMenuItem<String>(
                                  value: specialization,
                                  child: Text(
                                    specialization,
                                    style: appTheme
                                        .of(context)
                                        .titleMedium
                                        .override(
                                          fontFamily: 'Inter Tight',
                                          color:
                                              appTheme.of(context).primaryText,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialization = value;
                            _errorMessageSpecialization =
                                ''; // Clear error message
                          });
                        },
                      ),
                      SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _addSpecialization(_selectedSpecialization);
                              if (_errorMessageSpecialization.isEmpty) {
                                setState(() {
                                  _isAddingSpecialization = false;
                                });
                              }
                            },
                            child: Text(
                              'Add Specialization',
                              style: appTheme.of(context).titleMedium.override(
                                    fontFamily: 'Inter Tight',
                                    color: appTheme.of(context).success,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isAddingSpecialization = false;
                                _errorMessageSpecialization = '';
                                _selectedSpecialization = null;
                              });
                            },
                            child: Text(
                              'Cancel',
                              style: appTheme.of(context).titleMedium.override(
                                    fontFamily: 'Inter Tight',
                                    color: appTheme.of(context).success,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessageSpecialization.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Text(
                            _errorMessageSpecialization,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              specializations.isEmpty
                  ? Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.1),
                      child: Text('No specializations added yet.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: specializations.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: Key(specializations[index]),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await _confirmDeleteItem(
                                index, specializations);
                          },
                          background: Container(
                            color: Colors.red,
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 0.0,
                              horizontal: 8.0,
                            ),
                            title: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: predefinedColors[
                                    index % predefinedColors.length],
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Text(
                                specializations[index],
                                style: appTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: appTheme.of(context).primaryText,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
  
   Widget _buildFAB() {
   if (_currentView == 'Patient List') {
    // Existing FAB for adding pets
    return FloatingActionButton.extended(
      onPressed: () {
        final state = context.findAncestorStateOfType<MainScreenManagerState>();
        if (state != null) {
          state.onItemTapped(1); // Change to index 1
        } else {
          print('Error: MainScreenManager state not found');
        }
      },
      backgroundColor: const Color(0xFF249689),
      elevation: 8,
      label: Row(
        children: [
          Text(
            'Add Pet',
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
  } else if (_currentView == 'Appointments') {
    return FloatingActionButton.extended(
      onPressed: () {
        print('add appointment');
        _showAddEditAppointmentDialog( 0, true, 'doctor');
      },
      backgroundColor: const Color(0xFF249689),
      elevation: 8,
      label: Row(
        children: [
          Text(
            'Add Appointment ',
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
  } else {
    return SizedBox.shrink(); // Return an empty widget if no condition is met
  }
}

  Widget _buildPatientList() {
    return VetPatientListWidget();
  }

    Widget _buildAppointments() {
    return buildAppointmentWidget('doctor');
  }
}
