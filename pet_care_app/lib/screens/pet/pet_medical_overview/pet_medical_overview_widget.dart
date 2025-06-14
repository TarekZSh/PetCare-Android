import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:url_launcher/url_launcher.dart';
import '/common/app_theme.dart';
import '/common/app_utils.dart';
import 'package:flutter/material.dart';
import 'pet_medical_overview_model.dart';
export 'pet_medical_overview_model.dart';
import 'dart:async';
import 'all_item_page.dart';
import 'dart:io';

class PetMedicalOverviewWidget extends StatefulWidget {
  final Pet pet;

  const PetMedicalOverviewWidget({super.key, required this.pet});

  @override
  State<PetMedicalOverviewWidget> createState() =>
      _PetMedicalOverviewWidgetState();
}

class _PetMedicalOverviewWidgetState extends State<PetMedicalOverviewWidget> {
  late PetMedicalOverviewModel _model;
  final logger = Logger();
  late Pet _pet;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _medicalHistory = _pet.medicalHistory;
    _vaccinations = _pet.vaccinations;
    _model = createModel(context, () => PetMedicalOverviewModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

//add ,delete and edit  items
  List<Map<String, String>> _medicalHistory = [];
  List<Map<String, String>> _vaccinations = [];
  bool _isAddingMedicalHistory = false;
  bool _isAddingVaccination = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _doctorController = TextEditingController();
  bool _isTitleEmpty = false;
  bool _isDateEmpty = false;
  bool _isDoctorEmpty = false;
  bool _isMedicalHistoryFound = false;
  bool _isVaccinationFound = false;

  void _toggleAddItem(bool isAdding, Function(bool) setStateCallback) async {
    setState(() {
      setStateCallback(!isAdding);
    });
  }

  void _addItem(
    List<TextEditingController> controllers,
    List<dynamic> list,
    dynamic item,
    Function(bool) setStateCallback,
  ) async {
    bool itemExists = list.any((info) =>
        info['title'] == item['title'] &&
        info['date'] == item['date'] &&
        info['doctor'] == item['doctor']);

    if (controllers.every((controller) => controller.text.isNotEmpty) &&
        !itemExists) {
      setState(() {
        list.add(item);
        for (var controller in controllers) {
          controller.clear();
        }
        setStateCallback(false); // Hide the TextField after adding the item
      });

      // Save the updated list to Firestore
      try {
        final success = await _pet.updateToFirestore();
        if (success) {
          logger.d('Item added and Firestore updated successfully.');
        } else {
          logger.e('Failed to update Firestore after adding the item.');
        }
      } catch (e) {
        logger.e('Error updating Firestore: $e');
      }
    } else if (itemExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Item already exists!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelAddItem(List<TextEditingController> controllers,
      Function(bool) setStateCallback) {
    setState(() {
      for (var controller in controllers) {
        controller.clear();
      }
      setStateCallback(false);
      _isTitleEmpty = false;
      _isDateEmpty = false;
      _isDoctorEmpty = false;
      _isMedicalHistoryFound = false;
    });
  }

  void _deleteItem(int index, List<dynamic> list) async {
    setState(() {
      list.removeAt(index);
    });

    // Save the updated list to Firestore
    try {
      final success =
          await _pet.updateToFirestore(); // Assuming `_pet` is your Pet object
      if (success) {
        logger.d('Item deleted and Firestore updated successfully.');
      } else {
        logger.e('Failed to update Firestore after deleting the item.');
      }
    } catch (e) {
      logger.e('Error updating Firestore after deleting the item: $e');
    }
  }

  Future<bool> _confirmDeleteItem(
      int index, List<dynamic> list, String itemType) async {
    return await showDialog<bool>(
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
        ) ??
        false;
  }

  Future<void> _editItem(int index, List<dynamic> list, String itemType) async {
    final item = list[index];
    _titleController.text = item['title'];
    _dateController.text = item['date'];
    _doctorController.text = item['doctor'];

    void _updateState() {
      if (_titleController.text.isNotEmpty &&
          _dateController.text.isNotEmpty &&
          _doctorController.text.isNotEmpty) {
        setState(() {
          _isTitleEmpty = false;
          _isDateEmpty = false;
          _isDoctorEmpty = false;
          bool isItemFound = list.any((history) =>
              history['title'] == _titleController.text &&
              history['date'] == _dateController.text &&
              history['doctor'] == _doctorController.text &&
              list.indexOf(history) != index);
          if (itemType == 'medical history') {
            _isMedicalHistoryFound = isItemFound;
          } else {
            _isVaccinationFound = isItemFound;
          }
        });
      }
    }

    _titleController.addListener(_updateState);
    _dateController.addListener(_updateState);
    _doctorController.addListener(_updateState);

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: Text(itemType == 'medical history'
                  ? 'Edit Medical History'
                  : 'Edit Vaccination'),
              content: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Title',
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                fontSize: 15.5,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter a title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          errorText:
                              _isTitleEmpty ? 'Title cannot be empty' : null,
                        ),
                        onChanged: (text) {
                          dialogSetState(() {
                            _isTitleEmpty = text.isEmpty;
                            bool isItemFound = list.any((history) =>
                                history['title'] == _titleController.text &&
                                history['date'] == _dateController.text &&
                                history['doctor'] == _doctorController.text &&
                                list.indexOf(history) != index);
                            if (itemType == 'medical history') {
                              _isMedicalHistoryFound = isItemFound;
                            } else {
                              _isVaccinationFound = isItemFound;
                            }
                          });
                        },
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Date',
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                fontSize: 15.5,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'Select a date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                errorText: _isDateEmpty
                                    ? 'Date cannot be empty'
                                    : null,
                              ),
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null) {
                                  String formattedDate =
                                      DateFormat('MMMM dd, yyyy')
                                          .format(pickedDate);
                                  dialogSetState(() {
                                    _dateController.text = formattedDate;
                                    _isDateEmpty = false;
                                    bool isItemFound = list.any((history) =>
                                        history['title'] ==
                                            _titleController.text &&
                                        history['date'] ==
                                            _dateController.text &&
                                        history['doctor'] ==
                                            _doctorController.text &&
                                        list.indexOf(history) != index);
                                    if (itemType == 'medical history') {
                                      _isMedicalHistoryFound = isItemFound;
                                    } else {
                                      _isVaccinationFound = isItemFound;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                String formattedDate =
                                    DateFormat('MMMM dd, yyyy')
                                        .format(pickedDate);
                                dialogSetState(() {
                                  _dateController.text = formattedDate;
                                  _isDateEmpty = false;
                                  bool isItemFound = list.any((history) =>
                                      history['title'] ==
                                          _titleController.text &&
                                      history['date'] == _dateController.text &&
                                      history['doctor'] ==
                                          _doctorController.text);
                                  if (itemType == 'medical history') {
                                    _isMedicalHistoryFound = isItemFound;
                                  } else {
                                    _isVaccinationFound = isItemFound;
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Doctor\'s name',
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                fontSize: 15.5,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      TextField(
                        controller: _doctorController,
                        decoration: InputDecoration(
                          hintText: 'Enter doctor\'s name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          errorText: _isDoctorEmpty
                              ? 'Doctor\'s name cannot be empty'
                              : null,
                        ),
                        onChanged: (text) {
                          dialogSetState(() {
                            _isDoctorEmpty = text.isEmpty;
                            bool isItemFound = list.any((history) =>
                                history['title'] == _titleController.text &&
                                history['date'] == _dateController.text &&
                                history['doctor'] == _doctorController.text &&
                                list.indexOf(history) != index);
                            if (itemType == 'medical history') {
                              _isMedicalHistoryFound = isItemFound;
                            } else {
                              _isVaccinationFound = isItemFound;
                            }
                          });
                        },
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
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
                          _isTitleEmpty = _titleController.text.isEmpty;
                          _isDateEmpty = _dateController.text.isEmpty;
                          _isDoctorEmpty = _doctorController.text.isEmpty;
                        });

                        if (_isTitleEmpty || _isDateEmpty || _isDoctorEmpty) {
                          return;
                        }

                        bool isItemFound = list.any((history) =>
                            history['title'] == _titleController.text &&
                            history['date'] == _dateController.text &&
                            history['doctor'] == _doctorController.text &&
                            list.indexOf(history) != index);
                        if (isItemFound) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                itemType == 'medical history'
                                    ? 'Medical history with the same details already exists!'
                                    : 'Vaccination already exists!',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          list[index] = {
                            'title': _titleController.text,
                            'date': _dateController.text,
                            'doctor': _doctorController.text,
                          };
                        });

                        try {
                          final success = await _pet.updateToFirestore();
                          if (success) {
                            logger.d(
                                '$itemType updated and Firestore updated successfully.');
                          } else {
                            logger.e('Failed to update Firestore.');
                          }
                        } catch (e) {
                          logger.e('Error updating Firestore: $e');
                        }

                        _titleController.clear();
                        _dateController.clear();
                        _doctorController.clear();
                        _titleController.removeListener(_updateState);
                        _dateController.removeListener(_updateState);
                        _doctorController.removeListener(_updateState);
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
                        _titleController.clear();
                        _dateController.clear();
                        _doctorController.clear();
                        _titleController.removeListener(_updateState);
                        _dateController.removeListener(_updateState);
                        _doctorController.removeListener(_updateState);
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
  }

  Widget buildAddDialog(
      BuildContext context, String itemType, List<dynamic> list) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(screenWidth * 0.01,
          screenHeight * 0.01, screenWidth * 0.01, screenHeight * 0.01),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Title',
              style: appTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    fontSize: 15.5,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Enter a title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              errorText: _isTitleEmpty ? 'Title cannot be empty' : null,
            ),
            onChanged: (text) {
              setState(() {
                _isTitleEmpty = text.isEmpty;
                bool isItemFound = list.any((info) =>
                    info['title'] == text &&
                    info['date'] == _dateController.text &&
                    info['doctor'] == _doctorController.text);
                if (itemType == 'medical history') {
                  _isMedicalHistoryFound = isItemFound;
                } else {
                  _isVaccinationFound = isItemFound;
                }
              });
            },
          ),
          SizedBox(height: screenHeight * 0.02),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Date',
              style: appTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    fontSize: 15.5,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Select a date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    errorText: _isDateEmpty ? 'Date cannot be empty' : null,
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('MMMM dd, yyyy').format(pickedDate);
                      setState(() {
                        _dateController.text = formattedDate;
                        _isDateEmpty = false;
                        bool isItemFound = list.any((info) =>
                            info['title'] == _titleController.text &&
                            info['date'] == _dateController.text &&
                            info['doctor'] == _doctorController.text);
                        if (itemType == 'medical history') {
                          _isMedicalHistoryFound = isItemFound;
                        } else {
                          _isVaccinationFound = isItemFound;
                        }
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    String formattedDate =
                        DateFormat('MMMM dd, yyyy').format(pickedDate);
                    setState(() {
                      _dateController.text = formattedDate;
                      _isDateEmpty = false;
                      bool isItemFound = list.any((Info) =>
                          Info['title'] == _titleController.text &&
                          Info['date'] == _dateController.text &&
                          Info['doctor'] == _doctorController.text);
                      if (itemType == 'medical history') {
                        _isMedicalHistoryFound = isItemFound;
                      } else {
                        _isVaccinationFound = isItemFound;
                      }
                    });
                  }
                },
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Doctor\'s name',
              style: appTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    fontSize: 15.5,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          TextField(
            controller: _doctorController,
            decoration: InputDecoration(
              hintText: 'enter doctor\'s name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              errorText:
                  _isDoctorEmpty ? 'Doctor\'s name cannot be empty' : null,
            ),
            onChanged: (text) {
              setState(() {
                _isDoctorEmpty = text.isEmpty;
                bool isItemFound = list.any((info) =>
                    info['title'] == text &&
                    info['date'] == _dateController.text &&
                    info['doctor'] == _doctorController.text);
                if (itemType == 'medical history') {
                  _isMedicalHistoryFound = isItemFound;
                } else {
                  _isVaccinationFound = isItemFound;
                }
              });
            },
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isEmpty ||
                      _dateController.text.isEmpty ||
                      _doctorController.text.isEmpty) {
                    if (_titleController.text.isEmpty) {
                      setState(() {
                        _isTitleEmpty = true;
                      });
                    }
                    if (_dateController.text.isEmpty) {
                      setState(() {
                        _isDateEmpty = true;
                      });
                    }
                    if (_doctorController.text.isEmpty) {
                      setState(() {
                        _isDoctorEmpty = true;
                      });
                    }
                  } else {
                    bool infoExists = list.any((info) =>
                        info['title'] == _titleController.text &&
                        info['date'] == _dateController.text &&
                        info['doctor'] == _doctorController.text);

                    if (infoExists) {
                      // Show a red SnackBar if the medical history already exists
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            itemType == 'medical history'
                                ? 'Medical history with the same details already exists!'
                                : 'Vaccination already exists!',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return; // Exit early
                    }

                    setState(() {
                      _isTitleEmpty = false;
                      _isDateEmpty = false;
                      _isDoctorEmpty = false;
                      if (itemType == 'medical history') {
                        _isMedicalHistoryFound = infoExists;
                      } else {
                        _isVaccinationFound = infoExists;
                      }
                      if (!infoExists) {
                        if (itemType == 'medical history') {
                          _addItem(
                              [
                                _titleController,
                                _dateController,
                                _doctorController
                              ],
                              _medicalHistory,
                              {
                                'title': _titleController.text,
                                'date': _dateController.text,
                                'doctor': _doctorController.text,
                              },
                              (value) => _isAddingMedicalHistory = value);
                        } else {
                          _addItem(
                              [
                                _titleController,
                                _dateController,
                                _doctorController
                              ],
                              _vaccinations,
                              {
                                'title': _titleController.text,
                                'date': _dateController.text,
                                'doctor': _doctorController.text,
                              },
                              (value) => _isAddingVaccination = value);
                        }
                      }
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.of(context).success,
                  foregroundColor: Colors.white,
                ),
                child: Text('Add'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (itemType == 'medical history') {
                    _cancelAddItem(
                        [_titleController, _dateController, _doctorController],
                        (value) => _isAddingMedicalHistory = value);
                  } else {
                    _cancelAddItem(
                        [_titleController, _dateController, _doctorController],
                        (value) => _isAddingVaccination = value);
                  }
                },
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
    );
  }

  Widget buildItem(Map<String, String> entry, String itemType) {
    return Container(
      decoration: BoxDecoration(
        color: itemType == 'medical history'
            ? Color(0xFFE3F2FD)
            : Color(0xFFD2F4DE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['title']!,
                  style: appTheme.of(context).bodyLarge.override(
                        fontFamily: 'Inter',
                        color: itemType == 'medical history'
                            ? Colors.blue
                            : appTheme.of(context).success,
                        letterSpacing: 0.0,
                      ),
                ),
                Text(
                  entry['date']!,
                  style: appTheme.of(context).bodySmall.override(
                        fontFamily: 'Inter',
                        color: appTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                      ),
                ),
                Text(
                  'Dr. ${entry['doctor']}',
                  style: appTheme.of(context).bodySmall.override(
                        fontFamily: 'Inter',
                        color: appTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
            if (itemType == 'medical history')
              Icon(
                Icons.medical_services,
                color: Colors.blue,
                size: 24,
              )
            else
              Icon(
                Icons.vaccines_sharp,
                color: appTheme.of(context).success,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget buildItemList(BuildContext context, String itemType,
      List<dynamic> list, List<dynamic> Sortedlist) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: Sortedlist.take(3).map<Widget>((entry) {
        int index = list.indexOf(entry);
        return Column(
          children: [
            Dismissible(
              key: Key(entry['title']!),
              direction: DismissDirection.horizontal,
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  print('Edit');
                  await _editItem(index, list, itemType);
                  return false;
                } else {
                  return await _confirmDeleteItem(index, list, itemType);
                }
              },
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  _deleteItem(index, list);
                }
              },
              background: Container(
                color: Colors.grey,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 20),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              child: buildItem(entry, itemType),
            ),
            SizedBox(height: screenHeight * 0.02), // Add space between entries
          ],
        );
      }).toList(),
    );
  }

///////////////////build///////////////////////////////
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = 24.0;

    DateFormat dateFormat = DateFormat('MMMM d, yyyy');

// Ensure the dates are in the correct format before sorting
    List<Map<String, String>> sortedMedicalHistory =
        List<Map<String, String>>.from(_medicalHistory)
          ..sort((a, b) {
            try {
              return dateFormat
                  .parse(b['date']!)
                  .compareTo(dateFormat.parse(a['date']!));
            } catch (e) {
              print('Error parsing date in medical history: $e');
              return 0; // Treat them as equal if parsing fails
            }
          });

    List<Map<String, String>> sortedVaccinations =
        List<Map<String, String>>.from(_vaccinations)
          ..sort((a, b) {
            try {
              return dateFormat
                  .parse(b['date']!)
                  .compareTo(dateFormat.parse(a['date']!));
            } catch (e) {
              print('Error parsing date in vaccinations: $e');
              return 0; // Treat them as equal if parsing fails
            }
          });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            // Medical History Section
            Container(
              decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    screenWidth * 0.01,
                    screenHeight * 0.01,
                    screenWidth * 0.01,
                    screenHeight * 0.01),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              'Medical History',
                              style:
                                  appTheme.of(context).headlineSmall.override(
                                        fontFamily: 'Inter Tight',
                                        color: appTheme.of(context).success,
                                        letterSpacing: 0.0,
                                      ),
                            ),
                          ),
                        ),
                        if (!_isAddingMedicalHistory)
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: appTheme.of(context).success,
                              size: iconSize,
                            ),
                            onPressed: () => _toggleAddItem(
                              _isAddingMedicalHistory,
                              (value) => _isAddingMedicalHistory = value,
                            ),
                          ),
                      ],
                    ),
                    if (_isAddingMedicalHistory)
                      buildAddDialog(
                        context,
                        'medical history',
                        _medicalHistory,
                      ),
                    if (_medicalHistory.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: screenWidth * 0.1),
                        child: Text(
                          'No medical history recorded yet.',
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                fontSize: 15.5,
                                letterSpacing: 0.0,
                              ),
                        ),
                      )
                    else
                      buildItemList(
                        context,
                        'medical history',
                        _medicalHistory,
                        sortedMedicalHistory,
                      ),
                    if (_medicalHistory.length > 3)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllItemPage(
                                itemList: _medicalHistory,
                                itemType: 'medical history',
                                confirmDeleteItem: _confirmDeleteItem,
                                editItem: _editItem,
                                deleteItem: _deleteItem,
                                buildItem: buildItem,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: appTheme.of(context).success,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Vaccination Section
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    screenWidth * 0.01,
                    screenHeight * 0.01,
                    screenWidth * 0.01,
                    screenHeight * 0.01),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              'Vaccinations',
                              style:
                                  appTheme.of(context).headlineSmall.override(
                                        fontFamily: 'Inter Tight',
                                        color: appTheme.of(context).success,
                                        letterSpacing: 0.0,
                                      ),
                            ),
                          ),
                        ),
                        if (!_isAddingVaccination)
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: appTheme.of(context).success,
                              size: iconSize,
                            ),
                            onPressed: () => _toggleAddItem(
                              _isAddingVaccination,
                              (value) => _isAddingVaccination = value,
                            ),
                          ),
                      ],
                    ),
                    if (_isAddingVaccination)
                      buildAddDialog(
                        context,
                        'vaccination',
                        _vaccinations,
                      ),
                    if (_vaccinations.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: screenWidth * 0.1),
                        child: Text(
                          'No vaccinations recorded yet.',
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                fontSize: 15.5,
                                letterSpacing: 0.0,
                              ),
                        ),
                      )
                    else if(!_isAddingVaccination)
                      buildItemList(
                        context,
                        'vaccination',
                        _vaccinations,
                        sortedVaccinations,
                      ),
                    if (_vaccinations.length > 3)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllItemPage(
                                itemList: _vaccinations,
                                itemType: 'vaccinations',
                                confirmDeleteItem: _confirmDeleteItem,
                                editItem: _editItem,
                                deleteItem: _deleteItem,
                                buildItem: buildItem,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: appTheme.of(context).success,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Medical Documents Section
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  screenWidth * 0.01,
                  screenHeight * 0.01,
                  screenWidth * 0.01,
                  screenHeight * 0.01,
                ),
                child: MedicalDocumentsWidget(pet: _pet),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MedicalDocumentsWidget extends StatefulWidget {
  final Pet pet;

  const MedicalDocumentsWidget({required this.pet, Key? key}) : super(key: key);

  @override
  _MedicalDocumentsWidgetState createState() => _MedicalDocumentsWidgetState();
}

class _MedicalDocumentsWidgetState extends State<MedicalDocumentsWidget> {
  List<Map<String, String>> _documents = [];
  bool _isLoading = false; // State for loading indicator

  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _fetchDocuments(); // Fetch documents on initialization
  }

  // Fetch documents from Firestore for the current pet
  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.pet.id)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        setState(() {
          _documents = (data?['documents'] as List<dynamic>? ?? [])
              .map((doc) => Map<String, String>.from(doc))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch documents: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  // Upload a document to Firebase Storage and save its metadata in Firestore
  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'], // Allowed file types
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      setState(() {
        _isLoading = true; // Show loading indicator during upload
      });

      try {
        // Upload file to Firebase Storage under organized folder
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('pet_profiles/${widget.pet.id}/medical_documents/$fileName');
        await storageRef.putFile(file);

        // Get the download URL
        final downloadUrl = await storageRef.getDownloadURL();

        // Save document metadata to Firestore
        final documentData = {'name': fileName, 'url': downloadUrl};
        setState(() {
          _documents.add(documentData);
        });

        await FirebaseFirestore.instance
            .collection('pets')
            .doc(widget.pet.id)
            .set(
          {'documents': _documents},
          SetOptions(merge: true),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document uploaded: $fileName'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload document: $e'),
            duration: Duration(seconds: 2),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator after upload
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No document selected.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Delete a document from Firebase Storage and Firestore
  Future<void> _deleteDocument(int index) async {
    final document = _documents[index];

    setState(() {
      _isLoading = true; // Show loading indicator during deletion
    });

    try {
      // Delete from Firebase Storage under the organized path
      final storageRef = FirebaseStorage.instance.ref().child(
          'pet_profiles/${widget.pet.id}/medical_documents/${document['name']}');
      await storageRef.delete();

      // Remove from Firestore
      setState(() {
        _documents.removeAt(index);
      });
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.pet.id)
          .update({'documents': _documents});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document removed successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete document: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator after deletion
      });
    }
  }

  void _toggleView() {
    setState(() {
      _showAll = !_showAll; // Toggle the state
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine the number of documents to show based on the state
    final documentsToShow = _showAll ? _documents : _documents.take(3).toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'Medical Documents',
                    style: appTheme.of(context).headlineSmall.override(
                          fontFamily: 'Inter Tight',
                          color: appTheme.of(context).primary,
                          letterSpacing: 0.0,
                        ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.upload_file,
                  color: appTheme.of(context).primary,
                ),
                onPressed: () {
                  _uploadDocument();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : documentsToShow.isEmpty
                  ? Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.1),
                      child: Center(
                        child: Text(
                          'No medical history recorded yet.',
                          style: appTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                fontSize: 15.5,
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: documentsToShow.length,
                          itemBuilder: (context, index) {
                            final document = documentsToShow[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6.0, horizontal: 12.0),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 12.0,
                                  ),
                                  leading: Icon(
                                    Icons.insert_drive_file,
                                    color: appTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  title: Text(
                                    document['name']!,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteDocument(index);
                                    },
                                  ),
                                    onTap: () async {
                                    final url = document['url']!;
                                    Logger().d('Original URL: $url');
                                    try {
                                      // Parse the URL
                                      final uri = Uri.parse(url);
                                      Logger().d('Parsed URI: $uri');

                                      // Use url_launcher to open in an external browser or default PDF app
                                      if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication, // Open in an external application
                                      );
                                      } else {
                                      throw 'Could not launch $url';
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                      Logger().e('Failed to open document: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                      content: Text(
                                        'Failed to open ${document['name']}: $e'),
                                      ),
                                      );
                                      }
                                    }
                                    },
                                    
                                  ),
                            );
                          },
                        ),
                        if (_documents.length >
                            3) // Show button only if more than 3
                          TextButton(
                            onPressed: _toggleView,
                            child: Text(
                              _showAll ? 'View Less' : 'View More',
                              style: TextStyle(
                                color: appTheme.of(context).primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
        ],
      ),
    );
  }
}
