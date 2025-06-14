import 'dart:math';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:pet_care_app/firebase/pet_owner_class.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '/common/choice_chips_widget.dart';
import '/common/app_theme.dart';
import '/common/app_utils.dart';
import '/common/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'pet_owner_porfile_model.dart';
export 'pet_owner_porfile_model.dart';
import '../../services/edit_profile_name_bio.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care_app/services/notifications_service.dart';




class PetOwnerPetListWidget extends StatefulWidget {
  const PetOwnerPetListWidget({super.key});

  @override
  State<PetOwnerPetListWidget> createState() => _PetOwnerPetListWidgetState();
}



class _PetOwnerPetListWidgetState extends State<PetOwnerPetListWidget> {
  late PetOwnerPetListModel _model;
  late PetOwner _petOwner = PetOwner(
    id: 'dummy',
    name: 'Loading...',
    bio: '',
    phoneNumber: '',
    birthDay: '',
    imageUrl: null,
    pets: [],
  );
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late List<Pet> _pets = [];
  late List<Map<String,dynamic>>_events = [];
  final logger = Logger();

  late TextEditingController _nameController;
  late TextEditingController _bioController;

  String name = 'Example';
  String bio = 'Bio Example';
  String? imageUrl;
  File? _profileImage;




  void scheduleNotificationsForExistingAppointments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      final ownerDoc = await FirebaseFirestore.instance.collection('pet_owners').doc(user.uid).get();
      if (ownerDoc.exists) {
        final ownerData = ownerDoc.data();
        if (ownerData != null && ownerData.containsKey('petIds')) {
          for (var petId in ownerData['petIds']) {
            final petDoc = await FirebaseFirestore.instance.collection('pets').doc(petId).get();
            if (petDoc.exists) {
              final petData = petDoc.data();
              if (petData != null && (petData.containsKey('vetEvents'))) {
                for (var event in petData['vetEvents']){
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

                for (var event in petData['events']){
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
  void initState() {//async{
    logger.d('PetOwnerPetListWidget initState');
    super.initState();
    _model = createModel(context, () => PetOwnerPetListModel());
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _petOwner = authProvider.petOwner!;
    name = _petOwner.name;
    _nameController = TextEditingController(text: name);
    bio = _petOwner.bio;
    _bioController = TextEditingController(text: bio);
    _pets = _petOwner.pets;
  _initializeData();
  scheduleNotificationsForExistingAppointments();
  }


Future<void> _initializeData() async {
  _petOwner = (await PetOwner.fetchFromFirestore(_petOwner.id))!;
  _events = _petOwner.events;
  imageUrl = _petOwner.imageUrl;
}
  @override
  void dispose() {
    _model.dispose();
    _bioController.dispose();
    _nameController.dispose();
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
      // Optionally, show an error message to the user
    }
  }

  ////////////////////////////mays//////////////////

  void addEvent(Map<String, dynamic> event) {
    final petId = event['petId'];
    final petIndex = _pets.indexWhere((pet) => pet.id == petId);
    if (mounted){
    setState(() {
    // ✅ Update the pet's events
    _pets[petIndex].events.add(event);
    
    // ✅ Automatically sync petOwner's events from pets
    _events = _pets.expand((pet) => [...pet.events, ...pet.vetEvents]).toList();

    // ✅ Save changes to Firestore
    _pets[petIndex].saveToFirestore();
    //_petOwner.saveToFirestore();
  });
    }
  }

  void updateEvent(int index, Map<String, dynamic> event) async{
    _petOwner = (await PetOwner.fetchFromFirestore(_petOwner.id))!;
    _pets = _petOwner.pets;
    final eventToFind = _events[index];
    final oldPetId = eventToFind['petId'];
    final newPetId= event['petId'];
    final oldPetIndex = _pets.indexWhere((pet) => pet.id == oldPetId);
    final newPetIndex = _pets.indexWhere((pet) => pet.id == newPetId);
    _pets[oldPetIndex] = (await Pet.fetchFromFirestore(oldPetId))!;
    _pets[newPetIndex] = (await Pet.fetchFromFirestore(newPetId))!;
    //final oldEventIndex = _pets[oldPetIndex].events.indexWhere((event) => event == eventToFind);
    if(newPetIndex == oldPetIndex){
      if (mounted){
      setState(() {
        var eventIndex = _pets[oldPetIndex].events.indexWhere((event) => areMapsEqual(event,eventToFind));
        if(eventIndex == -1)
        {
          eventIndex = _pets[oldPetIndex].vetEvents.indexWhere((event) => areMapsEqual(event,eventToFind));
           _pets[newPetIndex].vetEvents[eventIndex] = event;
        }
        else{
          _pets[newPetIndex].events[eventIndex] = event;
        }
        _events[index] = event;
        _pets[newPetIndex].saveToFirestore();
      });
      }
      return;
    }
    else{
       final eventIndex = _pets[oldPetIndex].events.indexWhere((event) => areMapsEqual(event,eventToFind));
       _pets[oldPetIndex].events.removeAt(eventIndex);
       _pets[newPetIndex].events.add(event);
       _pets[oldPetIndex].saveToFirestore();
       _pets[newPetIndex].saveToFirestore();
    }
    if (mounted){
    
    setState(() {
      _events[index] = event;
    });
    }

  }

bool areMapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
  if (map1.length != map2.length) return false;
  for (String key in map1.keys) {
    if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
  }
  return true;
}


  Future<void> deleteEvent(int index) async{
    final eventToFind = _events[index];
    final petId = eventToFind['petId'];
    final petIndex = _pets.indexWhere((pet) => (pet.id == petId));
    _pets[petIndex] = (await Pet.fetchFromFirestore(petId))!;
    var eventIndex = _pets[petIndex].events.indexWhere((event) => areMapsEqual(event,eventToFind));
    if (eventIndex != -1) {
      _pets[petIndex].events.removeAt(eventIndex);
    }
    else{
        eventIndex = _pets[petIndex].vetEvents.indexWhere((event) => areMapsEqual(event,eventToFind));
        _pets[petIndex].vetEvents.removeAt(eventIndex);
    }
    //_events.removeAt(index);
    await _pets[petIndex].saveToFirestore();
    if (mounted){
        setState(()  {});
    }
  }

Future<void> deleteEventNoSave(int index)  async{
    final eventToFind = _events[index];
    final petId = eventToFind['petId'];
    final petIndex = _pets.indexWhere((pet) => (pet.id == petId));
    _pets[petIndex] = (await Pet.fetchFromFirestore(petId))!;
    var eventIndex = _pets[petIndex].events.indexWhere((event) => areMapsEqual(event,eventToFind));
    if (eventIndex != -1) {
      _pets[petIndex].events.removeAt(eventIndex);
    }
    else{
        eventIndex = _pets[petIndex].vetEvents.indexWhere((event) => areMapsEqual(event,eventToFind));
        _pets[petIndex].vetEvents.removeAt(eventIndex);
    }
    if(mounted){
              setState(()  {});
    }
  }

  void _addItem(Map<String, dynamic> event) async{
    final petId = event['petId'];
    final petIndex = _pets.indexWhere((pet) => pet.id == petId);
    // _pets[petIndex] = (await Pet.fetchFromFirestore(petId))!;

    
    List<Map<String, String>>list = event['eventType'] == 'Health and Wellness'
        ? _pets[petIndex].medicalHistory
        : _pets[petIndex].vaccinations;
    bool eventExists = list.any((info) =>
        info['title'] == event['title'] &&
        info['date'] == formatEventDateTime(event['date'], '', context) &&
        info['doctor'] == event['doctorName']);
    if (eventExists) {
      logger.e('The event already exists');
      return;
    }

    Map<String, String> item = {
      'date': formatEventDateTime(event['date'], '', context),
      'doctor': event['doctorName'],
      'title': event['title'],
    };

      list.add(item);

  try {
    await _pets[petIndex].saveToFirestore();
    logger.d('Event added and saved to Firestore');
    if (mounted){
    setState(() {});
    }
  } catch (e) {
    logger.e('Failed to save event to Firestore: $e');
  }
  }

  Future<bool?> _confirmDeleteItem(Map<String, dynamic> eventDetails, int index,
      {bool isDoctor = false, done = false}) async {

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
              onPressed: () async{
                if (done && (eventDetails['eventType'] == 'Health and Wellness' ||eventDetails['eventType'] == 'Vaccination')) {
                  await deleteEventNoSave(index);
                  _addItem(eventDetails);
                  print('Done button pressed');
                }
                else{
                  deleteEvent(index);
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

void _showAddEditEventDialog(int index, bool isAdding, String type) async {
  _petOwner = (await PetOwner.fetchFromFirestore(_petOwner.id))!;
  final titleController = TextEditingController(text: isAdding ? '' : _events[index]['title']);
  DateTime? selectedDate = isAdding ? null : DateTime.parse(_events[index]['date']);
  TimeOfDay? selectedTime = isAdding ? null : _parseTime(_events[index]['time']);
  String? eventType = isAdding ? null : _events[index]['eventType'];
  final doctorNameController = TextEditingController(text: isAdding ? '' : _events[index]['doctorName']);
  final shaverNameController = TextEditingController(text: isAdding ? '' : _events[index]['shaverName']);
  final notesController = TextEditingController(text: isAdding ? '' : _events[index]['notes']);
  String? petId = isAdding ? null : _events[index]['petId'];
  Pet? selectedPet = isAdding ? null : _pets.firstWhere((pet) => pet.id == petId);
  DateTime? oldDate = selectedDate;
  TimeOfDay? oldTime = selectedTime;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.blue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0x66000000), // Semi-transparent overlay
                ),
                child: Builder(
                  builder: (scaffoldContext) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.9),
                      title: Text(
                        isAdding ? "Add New Event" : "Edit Event",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      content: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title Input
                                Row(
                                  children: [
                                    Text(
                                      "Title",
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text("*", style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: titleController,
                                  decoration: const InputDecoration(
                                    hintText: "Enter title",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Pet Name Dropdown
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
                                          const SizedBox(width: 4),
                                          const Text("*", style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<Pet>(
                                        value: isAdding
                                            ? null
                                            : _petOwner.pets.firstWhere((pet) => pet.id == _events[index]['petId']),
                                        items: _petOwner.pets.map((pet) {
                                          return DropdownMenuItem<Pet>(
                                            value: pet,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundImage: pet.imageUrl != null
                                                      ? NetworkImage(pet.imageUrl!)
                                                      : const AssetImage('assets/images/PetProfilePicture.png')
                                                          as ImageProvider,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(pet.name),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (Pet? value) {
                                          selectedPet = value;
                                          setState(() {});
                                        },
                                        decoration: const InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 16),

                                // Date Picker
                                Row(
                                  children: [
                                    Text(
                                      "Date",
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text("*", style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                                const SizedBox(height: 8),
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

                                // Time Picker
                                Row(
                                  children: [
                                    Text(
                                      "Time",
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text("*", style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                                const SizedBox(height: 8),
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

                                const SizedBox(height: 16),

                                // Event Type Dropdown
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
                                          const SizedBox(width: 4),
                                          const Text("*", style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
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
                                        decoration: const InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 16),

                                // Doctor or Shaver Name
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
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                    ),
                                  ),
                        ],
                                if (eventType == 'Grooming')...[
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
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                                if (eventType == 'Other')
                                  TextField(
                                    controller: notesController,
                                    maxLines: 3,
                                    maxLength: 50,
                                    decoration: const InputDecoration(
                                      hintText: "Notes",
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                    ),
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
                                selectedPet == null ||
                                selectedDate == null ||
                                selectedTime == null ||
                                eventType == null ||
                    
                    ( ((eventType == 'Health and Wellness') || (eventType == 'Vaccination') )&& doctorNameController.text.isEmpty) ||
                    (eventType == 'Grooming' && shaverNameController.text.isEmpty)) {
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
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
                  'petId': selectedPet?.id,
                  'date': selectedDate?.toIso8601String() ?? '',
                  'time': selectedTime?.format(context) ?? '',
                  'eventType': eventType,
                  'doctorName': doctorNameController.text,
                  'shaverName': shaverNameController.text,
                  'notes': notesController.text,
                };
                bool eventExists = _events.any((event) =>
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
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(isAdding ? "Add" : "Save"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            //backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
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

  Widget buildEvent(
      Map<String, dynamic> eventDetails, String eventType, String userTybe) {                   
    // Define the icon, color, and other details based on eventType
    IconData icon;
    Color iconColor;
    Color backgroundColor;
    String title;
    String petNameText;
    Pet pet = _pets.firstWhere((pet) => pet.id == eventDetails['petId']);

    switch (eventType) {
      case 'Health and Wellness':
        icon = Icons.medical_services;
        iconColor = appTheme.of(context).success;
        backgroundColor = Color(0xFFE8F5E9);
        title = eventDetails['title'];
        petNameText = 'For ${pet.name}';
        break;
      case 'Vaccination':
        icon = Icons.vaccines;
        iconColor = Colors.orange;
        backgroundColor = Color(0xFFFFF3E0);
        title = eventDetails['title'];
        petNameText = 'For ${pet.name}';
        break;
      case 'Grooming':
        icon = Icons.content_cut;
        iconColor = Colors.blue;
        backgroundColor = Color(0xFFE3F2FD);
        title = eventDetails['title'];
        petNameText = 'For ${pet.name}';
        break;
      case 'Other':
        icon = Icons.pets;
        iconColor = Color(0xFF969224);
        backgroundColor = Color(0xFFEEEFD8);
        title = eventDetails['title'];
        petNameText = 'For ${pet.name}';
        break;
      default:
        // For unknown event types, show basic ListTile
        return ListTile(
          title: Text(eventDetails['title']),
          subtitle:
              Text('${pet.name} - ${eventDetails['eventType']}'),
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
  radius: MediaQuery.of(context).size.width * 0.05, // Adjust the radius as needed
  child: IconButton(
    onPressed: () {
      int index = _events.indexWhere((event) => areMapsEqual(event, eventDetails));
      _confirmDeleteItem(eventDetails, index,
          isDoctor: userTybe == 'doctor', done: true);

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


  Future<Widget> buildUpComingEventsWidget(String userType) async {
    _petOwner = (await PetOwner.fetchFromFirestore(_petOwner.id))!;
    _events = [];
    for(var pet in _petOwner.pets){
      _events.addAll(pet.events);
      _events.addAll(pet.vetEvents);
    }
    print('build Up-Coming Events Widget');
    sortEventsByDateTime(_events);
    // Avoid using Scaffold and Expanded if already wrapped in another layout
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
  children: [
    SizedBox(height: screenHeight * 0.02), // Add a SizedBox at the top
    _events.isEmpty
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
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[index];
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
                        _showAddEditEventDialog(index, false, 'pet owner');
                        return false;
                      } else if (direction == DismissDirection.endToStart) {
                        return await _confirmDeleteItem(event, index);
                      }
                      return false;
                    },
                    child: buildEvent(event, event['eventType'] ?? 'Health and Wellness', 'petOwner'),
                  ),
                  SizedBox(height: 16), // Add a SizedBox between each event
                ],
              );
            },
          ),
  ],
);
  }

  /////////////////build method////////////////
  Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  // Access the AuthProvider
  final authProvider = Provider.of<AuthProvider>(context);

  return GestureDetector(
    onTap: () {
      FocusScope.of(context).unfocus();
    },
    child: Scaffold(
      key: scaffoldKey,
      backgroundColor: appTheme.of(context).primaryBackground,

      // Floating Action Button
      floatingActionButton: _buildFAB(),

      body: Container(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            _buildGradientBackground(),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEditProfileButton(),
                    _buildProfileHeader(),
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
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildChoiceChips(),
                              ////////////////////// Pets List //////////////////////
                               _buildOverView(authProvider),
                              //////////////////// End Pets List ////////////////////
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
    ),
  );
}
  Widget _buildEditProfileButton() {
    int iconSize = 24;
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
          child: PopupMenuButton<String>(
            onSelected: (String result) async {
              if (result == 'Edit') {
                if (name == 'Example') {
                  _nameController.clear();
                }
                if (bio == 'Bio Example') {
                  _bioController.clear();
                }
                await PetOwner.fetchFromFirestore(_petOwner.id).then((petOwner) {
                  _petOwner = petOwner!;
                });
                showEditProfileDialog(
                  context,
                  _nameController,
                  _bioController,
                  imageUrl,
                  name,
                  bio,
                  (imageFile, newImageUrl) {
                    if (mounted) {
                    // Handle image selection
                    setState(() {
                      _profileImage = imageFile;
                      imageUrl = newImageUrl;
                    });
                    }
                  },
                  () {
                    if (mounted) {
                    // Handle image deletion
                    setState(() {
                      _profileImage = null;
                      imageUrl = '';
                    });
                    }
                  },
                  tybe: 'pet owner',
                ).then((bool result) {
                  // Check the result of the dialog
                  if (result) {
                    if (mounted) {
                    // If Save was clicked, update local state immediately
                    setState(() {
                      name = _nameController.text;
                      bio = _bioController.text;
                      logger.d('the old image is $imageUrl');
                      imageUrl = (_profileImage == null && imageUrl == '') ? null : imageUrl;// Temporary update
                      logger.d('The new image is $_profileImage');
                      logger.d('The new image URL is $imageUrl');
                      _petOwner.imageUrl = imageUrl; 
                    });
                    }
                    // Perform Firebase and Firestore updates asynchronously
                    Future.microtask(() async {
                        // Update the Pet Owner object with new values
                        _petOwner.name = name;
                        _petOwner.bio = bio;
                        _petOwner.imageUrl = imageUrl;
                        logger.d(
                            'The pet owner image URL is ${_petOwner.imageUrl}');

                        // Save changes to Firestore
                        await _petOwner.saveToFirestore();
                        logger.d('Pet owner profile updated in Firestore');
                    });
                  } else {
                    if (mounted) {
                    // If Cancel was clicked, revert any local changes
                    setState(() {
                      _nameController.text = name;
                      _bioController.text = bio;
                      _profileImage = null; // Reset profile image
                      imageUrl = imageUrl; // Keep the current image
                    });
                    }
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
                    const Icon(Icons.info, color: Colors.black),
                    const SizedBox(width: 8.0),
                    const Text('Info'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.black),
                    const SizedBox(width: 8.0),
                    const Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.black),
                    const SizedBox(width: 8.0),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
            icon: Padding(
              padding:
                  const EdgeInsets.only(top: 35), // Adjust the value as needed
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33FFFFFF), // White transparent circle
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

// filepath: /c:/Users/maysk/OneDrive/Desktop/2025a-petcare/pet_care_app/lib/screens/pet_owner/pet_owner_pet_list_widget.dart

String getClosestEventTitle(List<Map<String, dynamic>> events, List<Map<String, dynamic>> vetEvents) {
  DateTime now = DateTime.now();
  Map<String, dynamic>? closestEvent;
  DateTime? closestDateTime;

  for (var event in events) {
    try {
      DateTime eventDateTime = _parseDateTime(event['date'], event['time']);
      int daysUntilEvent = eventDateTime.difference(now).inDays;
      if(daysUntilEvent < 0){
        continue;
      }
      if (closestDateTime == null || (eventDateTime.isBefore(closestDateTime) )) {
            logger.d('daysUntilEvent: $daysUntilEvent');
            logger.d('The event date time is $eventDateTime');
            logger.d('Now: $now (Local: ${now.toLocal()})');
            logger.d('Event DateTime: $eventDateTime (Local: ${eventDateTime.toLocal()})');
        closestDateTime = eventDateTime;
        closestEvent = event;
      }
    } catch (e) {
      print('Error parsing event date/time: $e');
    }
  }

  for (var vetEvent in vetEvents) {
    try {
      DateTime vetEventDateTime = _parseDateTime(vetEvent['date'], vetEvent['time']);
      int daysUntilEvent = vetEventDateTime.difference(now).inDays;
      if(daysUntilEvent < 0){
        continue;
      }
      if (closestDateTime == null || (vetEventDateTime.isBefore(closestDateTime))) {
        closestDateTime = vetEventDateTime;
        closestEvent = vetEvent;
      }
    } catch (e) {
      print('Error parsing vet event date/time: $e');
    }
  }

 if (closestEvent != null) {
  int daysUntilEvent = closestDateTime!.difference(now).inDays;

  // Determine the time description based on daysUntilEvent
  String timeDescription;
  if (daysUntilEvent == 0) {
    timeDescription = 'today';
  } else if (daysUntilEvent == 1) {
    timeDescription = 'tomorrow';
  } else if (daysUntilEvent >= 30 && daysUntilEvent < 365) {
    int monthsUntilEvent = (daysUntilEvent / 30).floor(); // Approximate months
    timeDescription = 'in $monthsUntilEvent month${monthsUntilEvent > 1 ? 's' : ''}';
  } else if (daysUntilEvent >= 365) {
    int yearsUntilEvent = (daysUntilEvent / 365).floor(); // Approximate years
    timeDescription = 'in $yearsUntilEvent year${yearsUntilEvent > 1 ? 's' : ''}';
  } else {
    timeDescription = 'in $daysUntilEvent days';
  }

  return '${closestEvent['title']} $timeDescription';
} else {
    List<String> funnyMessages = [
      "No upcoming events. Time for a nap!",
      "No upcoming events. Where's the party?",
      "No upcoming events. Your pet is on vacation!",
      "No upcoming events. Playtime?",
      "No upcoming events. Snack time!"
    ];
    Random random = Random();
    return funnyMessages[random.nextInt(funnyMessages.length)];
  }
}



  Widget buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () {
        // Handle the onClick event here
        context.push('/pet-profile', extra: pet);
      },
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Material(
                    color: Colors.transparent,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                            ? Image.network(
                                pet.imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/PetProfilePicture.png', // Replace with your default image asset
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 0),
                          child: Text(
                            pet.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontFamily: 'Inter Tight',
                                  color: Theme.of(context).primaryColorDark,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 0),
                          child: Text(
                            '${pet.species} • ${pet.age} years',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontFamily: 'Inter',
                                  color: Theme.of(context).hintColor,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width * 1, // Set the minimum height to ensure it is at least one line high
                            ),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
                              child: Text(
                                getClosestEventTitle(pet.events, pet.vetEvents), // Replace with dynamic data
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontFamily: 'Inter',
                                      color: Theme.of(context).colorScheme.secondary,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildFAB() {
    if (_model.choiceChipsValue == 'My pets' || _model.choiceChipsValue == null) {
      // Existing FAB for adding pets
      return FloatingActionButton.extended(
        onPressed: () {
            context.push('/add-pet');
        },
        backgroundColor: const Color(0xFF249689),
        elevation: 8,
        label: Row(
          children: [
            Text(
              'Add Pet ',
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
      return FloatingActionButton.extended(
        onPressed: () {
          print('add event');
          _showAddEditEventDialog(0, true, 'pet Owner');
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
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Container(
        height: 250.0, // Adjusted height for better spacing
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
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
                                                'assets/images/petOwnerProfile.png')
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
                            : AssetImage('assets/images/petOwnerProfile.png')
                                as ImageProvider,
                  ),
                ),
              ),
            ),

            // Name
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AutoSizeText(
                name,
                textAlign: TextAlign.center,
                style: appTheme.of(context).headlineMedium.override(
                      fontFamily: 'Inter Tight',
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.0,
                    ),
                maxLines: 1,
                minFontSize: 12, // Minimum font size
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis if the text overflows
              ),
            ),

            // Bio
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AutoSizeText(
                bio,
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
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChips() {
    return appChoiceChips(
      options: [
        ChipData('My pets'),
        ChipData('Upcoming Events'),
      ],
      onChanged: (val) =>
          safeSetState(() => _model.choiceChipsValue = val?.firstOrNull),
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
        ['My pets'],
      ),
      wrapped: true,
    );
  }

  Widget _buildOverView(authProvider) {
    if (_model.choiceChipsValue == 'My pets') {
      return _showMyPets(authProvider);
    } else {
      return _showUpcomingEvents();
    }
  }

  Widget _showMyPets(authProvider) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
      if (authProvider.petOwner?.pets.isEmpty ?? true) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.pets,
          color: Colors.grey,
          size: 48,
        ),
        SizedBox(height: screenHeight * 0.02),
        Text(
          'No pets yet',
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  } else {
    return ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: authProvider.petOwner?.pets.length ?? 0 ,
  itemBuilder: (context, index) {
    final pet = authProvider.petOwner!.pets[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Dismissible(
        key: Key(pet.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Confirm Deletion'),
                content: Text('Are you sure you want to delete this pet?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete'),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          // Remove the pet from the list and update Firestore
          if(mounted)
          {         
            setState(() {
              authProvider.petOwner!.pets.removeAt(index);
            });
          }
          authProvider.petOwner!.saveToFirestore();

          // Call a method to delete the pet from Firestore
          final collection = FirebaseFirestore.instance.collection('pets');
          collection.doc(pet.id).delete();
        },
        child: buildPetCard(pet),
      ),
    );
  },
);
  }
  }
  
Widget _showUpcomingEvents() {
  return FutureBuilder<Widget>(
    future: buildUpComingEventsWidget('pet owner'),
    builder: (context, snapshot) {
      return snapshot.data ?? Center();
    },
  );
}
}