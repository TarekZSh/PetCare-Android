import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:pet_care_app/common/app_theme.dart';
import 'package:pet_care_app/common/custom_widgets.dart';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:pet_care_app/firebase/vet_class.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/chat/chat_screen.dart';
import 'package:pet_care_app/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PetDetailModal {
  static Future<void> show(BuildContext context, Pet pet, int index,
      {VoidCallback? onUpdate}) async {
    bool isVetPatient = false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId =
        authProvider.petOwner?.id ?? authProvider.vet?.id ?? '';

    String userType = authProvider.petOwner != null ? 'Pet Owner' : 'Vet';
    if (userType == 'Vet') {
      isVetPatient =
          authProvider.vet?.patients.any((patient) => patient.id == pet.id) ??
              false;
    }

    Color backgroundColor = (index % 2 == 0
        ? const Color(0xFFE8F5E9) // Light Green for Pets
        : const Color(0xFFE3F2FD));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isExpandedSpecialNotes = false;
            bool isExpandedActivities = false;
            bool isExpandedMedicalHistory = false;
            bool isExpandedVacinations = false;
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section with Pet Image
                          Center(
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: pet.imageUrl != null
                                  ? NetworkImage(pet.imageUrl!)
                                  : const AssetImage(
                                          'assets/images/PetProfilePicture.png')
                                      as ImageProvider,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Pet Name
                          Center(
                            child: Text(
                              pet.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Pet Details Section
                          _buildSectionTitle(context, 'Pet Details'),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    children: [
                                      _buildPetDetailCard(
                                          'Gender',
                                          pet.gender ?? 'Unknown',
                                          Colors.black),
                                      _buildPetDetailCard(
                                          'Type', pet.species, Colors.black),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      _buildPetDetailCard('Breed',
                                          pet.breed ?? 'Unknown', Colors.black),
                                      _buildPetDetailCard('Owner',
                                          pet.owner ?? 'Unknown', Colors.black),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Health Overview Section
                          _buildSectionTitle(context, 'Health Overview'),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _buildHealthDetail(
                                        'Weight', '${pet.weight} kg'),
                                  ),
                                  Expanded(
                                    child: _buildHealthDetail(
                                        'Height', '${pet.height} cm'),
                                  ),
                                  Expanded(
                                    child: _buildHealthDetail(
                                        'Age', '${pet.age} yrs'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Special Notes Section
                          _buildSectionTitle(context, 'Special Notes'),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: StatefulBuilder(
                              builder: (context, setState) {
                                // Determine the list to display based on the expanded state
                                final displayNotes = isExpandedSpecialNotes
                                    ? pet.specialNotes
                                    : pet.specialNotes.take(3).toList();

                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: pet.specialNotes.isNotEmpty
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ...displayNotes.map((noteMap) {
                                              final note = noteMap.values
                                                      .elementAt(1) ??
                                                  'No note available'; // Extract the 'note' value
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      noteMap.values.elementAt(
                                                                  0) ==
                                                              'Allergies'
                                                          ? Icons.block
                                                          : noteMap.values
                                                                      .elementAt(
                                                                          0) ==
                                                                  'Behavioral Notes'
                                                              ? Icons.warning
                                                              : noteMap.values
                                                                          .elementAt(
                                                                              0) ==
                                                                      'Medical Conditions'
                                                                  ? Icons
                                                                      .medical_services
                                                                  : Icons.notes,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        note,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                                color: Colors
                                                                    .black87),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            if (pet.specialNotes.length > 3)
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    isExpandedSpecialNotes =
                                                        !isExpandedSpecialNotes;
                                                  });
                                                },
                                                child: Text(
                                                  isExpandedSpecialNotes
                                                      ? 'Show Less'
                                                      : 'Show More',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      : Center(
                                          child: Text(
                                            'No special notes recorded.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          if (isVetPatient)
                            _buildMedicalHistorySection(
                                context, pet, isExpandedMedicalHistory),

                          const SizedBox(
                            height: 8,
                          ),
                          if (isVetPatient)
                            _buildVaccinationSection(
                                context, pet, isExpandedVacinations),

                          const SizedBox(height: 8),
                          // Last Activities Section
                          _buildSectionTitle(context, 'Last Activities'),

                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: StatefulBuilder(
                              builder: (context, setState) {
                                bool isExpanded = false;

                                // Determine the list to display based on the expanded state
                                final displayActivities = isExpanded
                                    ? pet.lastActivities
                                    : pet.lastActivities.take(3).toList();

                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: pet.lastActivities.isNotEmpty
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 8),
                                            ...displayActivities
                                                .map((activity) {
                                              final activityNote = activity ??
                                                  'No activity recorded';
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons.local_activity,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        activityNote,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                                color: Colors
                                                                    .black87),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            if (pet.lastActivities.length > 3)
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    isExpandedActivities =
                                                        !isExpandedActivities;
                                                  });
                                                },
                                                child: Text(
                                                  isExpandedActivities
                                                      ? 'Show Less'
                                                      : 'Show More',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      : Center(
                                          child: Text(
                                            'No recent activities recorded.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (isVetPatient) MedicalDocumentsSection(pet: pet),
                          const SizedBox(height: 8),
                          _buildSectionTitle(context, 'Preferences'),

                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: pet.preferences.entries
                                      .where((entry) => entry
                                          .value) // Show only preferences with true value
                                      .isNotEmpty
                                  ? Wrap(
                                      spacing: 8.0,
                                      runSpacing: 8.0,
                                      alignment: WrapAlignment.start,
                                      children: pet.preferences.entries
                                          .where((entry) => entry.value)
                                          .map((entry) {
                                        return Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4, // Stretch each chip
                                          child: Chip(
                                            label: Center(
                                              child: Text(
                                                entry.key,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  : Center(
                                      child: Text(
                                        'No preferences added.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.grey,
                                            ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          const SizedBox(height: 16),
                          // Dynamic Button
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Button for adding/removing the pet to/from the patient list
                                if (userType == 'Vet')
                                  ButtonWidget(
                                    onPressed: () async {
                                      Vet vet = authProvider.vet!;
                                      try {
                                        // Perform add/remove operation immediately
                                        if (isVetPatient) {
                                          // Remove the pet from the vet's patient list
                                          vet.patients.remove(pet);
                                          await vet.saveToFirestore();

                                          setState(() {
                                            isVetPatient = false;
                                          });

                                          if (onUpdate != null) {
                                            onUpdate();
                                          }
                                        } else {
                                          // Add the pet to the vet's patient list
                                          vet.patients.add(pet);
                                          await vet.saveToFirestore();

                                          setState(() {
                                            isVetPatient = true;
                                          });

                                          if (onUpdate != null) {
                                            onUpdate();
                                          }
                                        }

                                        // Perform Firestore existence check in the background
                                        FirebaseFirestore.instance
                                            .collection('pets')
                                            .doc(pet.id)
                                            .get()
                                            .then(
                                          (doc) async {
                                            if (!doc.exists) {
                                              // Notify the user if the pet has been deleted
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${pet.name} has been deleted and removed from your patients list.',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );

                                              // Remove the deleted pet from the vet's patient list
                                              vet.patients.removeWhere(
                                                  (p) => p.id == pet.id);
                                              await vet.saveToFirestore();
                                            }
                                          },
                                        );
                                      } catch (e) {
                                        // Handle Firestore errors
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('An error occurred: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    text: isVetPatient
                                        ? 'Remove from Patient List'
                                        : 'Add to Patient List',
                                    icon: Icon(
                                      isVetPatient
                                          ? Icons.remove_circle_outline
                                          : Icons.add_circle_outline,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                    options: ButtonOptions(
                                      height: 50.0,
                                      width: MediaQuery.of(context).size.width *
                                          0.7,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      color: isVetPatient
                                          ? Colors.red // Red for "Remove"
                                          : Theme.of(context)
                                              .primaryColor, // Default color for "Add"
                                      textStyle: appTheme
                                          .of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'Inter Tight',
                                            color: Colors.white,
                                            letterSpacing: 0.0,
                                          ),
                                      textAlign: TextAlign.start,
                                      iconAlignment: IconAlignment.start,
                                      borderRadius: BorderRadius.circular(16),
                                      iconSize: 24.0,
                                      iconColor: Colors.white,
                                    ),
                                  ),

                                const SizedBox(
                                    height: 20), // Spacing between buttons

                                // Button for connecting with the pet owner
                                if (currentUserId != pet.ownerId)
                                  ButtonWidget(
                                    onPressed: () async {
                                     // return  ;
                                      final chatService =
                                          ChatService(); // Instance of ChatService

                                      if (authProvider.vet == null &&
                                          authProvider.petOwner == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'You must be logged in to start a chat.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      final participantId =
                                          pet.ownerId; // Pet owner's ID

                                      final participantName =
                                          pet.owner; // Pet owner's name
                                      String participantImageUrl = '';

                                      try {
                                        // Fetch participant image URL
                                        final participantDoc =
                                            await FirebaseFirestore.instance
                                                .collection('pet_owners')
                                                .doc(participantId)
                                                .get();

                                        if (participantDoc.exists) {
                                          participantImageUrl = participantDoc
                                                  .data()?['imageUrl'] ??
                                              '';
                                        }
                                      } catch (e) {
                                        print(
                                            'Error fetching participant image URL: $e');
                                      }

                                      try {
                                        // Check if a chat already exists
                                        final existingChat =
                                            await FirebaseFirestore
                                                .instance
                                                .collection('Chats')
                                                .where('participants',
                                                    arrayContains:
                                                        currentUserId)
                                                .get();

                                        String? chatId;

                                        try {
                                          final chat =
                                              existingChat.docs.firstWhere(
                                            (doc) => (doc.data()['participants']
                                                    as List<dynamic>)
                                                .contains(participantId),
                                          );

                                          chatId = chat
                                              .id; // Use the existing chat ID
                                        } catch (e) {
                                          // Create a new chat if no existing chat is found
                                          chatId = await chatService.createChat(
                                              [currentUserId, participantId]);
                                        }

                                        // Navigate to the Chat Screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              chatId: chatId!,
                                              participantName: participantName,
                                              participantImageUrl:
                                                  participantImageUrl,
                                              type: 'pet_owner',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        print('Failed to initialize chat: $e');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Failed to start chat. Please try again later.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    text: 'Connect with Owner',
                                    icon: const Icon(
                                      Icons.chat_outlined,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                    options: ButtonOptions(
                                      height: 50.0,
                                      width: MediaQuery.of(context).size.width *
                                          0.7,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      color: Theme.of(context).primaryColor,
                                      textStyle: appTheme
                                          .of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'Inter Tight',
                                            color: Colors.white,
                                            letterSpacing: 0.0,
                                          ),
                                      textAlign: TextAlign.start,
                                      iconAlignment: IconAlignment.start,
                                      borderRadius: BorderRadius.circular(16),
                                      iconSize: 24.0,
                                      iconColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

static Widget _buildVaccinationSection(
    BuildContext context, Pet pet, bool isExpanded) {
  return StatefulBuilder(
    builder: (context, setState) {
      final displayVaccinations =
          isExpanded ? pet.vaccinations : pet.vaccinations.take(3).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Vaccination Status'),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: pet.vaccinations.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...ListTile.divideTiles(
                          context: context,
                          color: Colors.grey[300], // Divider color
                          tiles: displayVaccinations.map((vaccination) {
                            final vaccine = vaccination['title'] ??
                                'No vaccine specified';
                            final date =
                                vaccination['date'] ?? 'No date provided';
                            final doctor =
                                vaccination['doctor'] ?? 'No doctor specified';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.vaccines_outlined,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$vaccine\n',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          TextSpan(
                                            text:
                                                'Date: $date\nAdministered by: $doctor',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ).toList(),
                        if (pet.vaccinations.length > 3)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: Text(
                              isExpanded ? 'Show Less' : 'Show More',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Text(
                        'No vaccination records found.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
            ),
          ),
        ],
      );
    },
  );
}


  static Widget _buildMedicalHistorySection(
    BuildContext context, Pet pet, bool isExpanded) {
  return StatefulBuilder(
    builder: (context, setState) {
      final displayHistory =
          isExpanded ? pet.medicalHistory : pet.medicalHistory.take(3).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Medical History'),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: pet.medicalHistory.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...ListTile.divideTiles(
                          context: context,
                          color: Colors.grey[300], // Divider color
                          tiles: displayHistory.map((history) {
                            final condition =
                                history['title'] ?? 'No condition specified';
                            final date =
                                history['date'] ?? 'No date provided';
                            final doctor =
                                history['doctor'] ?? 'No doctor specified';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.medical_services_outlined,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$condition\n',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          TextSpan(
                                            text:
                                                'Date: $date\nDoctor: $doctor',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ).toList(),
                        if (pet.medicalHistory.length > 3)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: Text(
                              isExpanded ? 'Show Less' : 'Show More',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Text(
                        'No medical history recorded yet.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
            ),
          ),
        ],
      );
    },
  );
}

  static Widget _buildPetDetailCard(String label, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  static Widget _buildHealthDetail(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class VetDetailModal {
  static void show(BuildContext context, Vet vet, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final backgroundColor = (index % 2 == 0
        ? const Color(0xFFFFF3E0) // Light Yellow for Vets
        : const Color(0xFFFFE0B2)); // Light Peach for Vets
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: vet.imageUrl != null
                              ? NetworkImage(vet.imageUrl!)
                              : const AssetImage('assets/images/vetProfile.png')
                                  as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Vet Name
                      Center(
                        child: Text(
                          vet.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'about: ${vet.bio}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'Contact Info'),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildContactInfo(context, 'Email', vet.email),
                              const SizedBox(height: 8),
                              _buildContactInfo(context, 'Phone', vet.phone),
                              const SizedBox(height: 8),
                              _buildContactInfo(
                                  context, 'Location', vet.location),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Specializations Section
                      _buildSectionTitle(context, 'Specializations'),
                      Center(
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: vet.specializations.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: vet.specializations
                                        .map((specialization) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star,
                                                color: Colors.orange, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              specialization,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                      color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : Center(
                                    child: Text(
                                      'No specializations listed.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'Experience'),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildVetDetailCard('Experience',
                                  '${vet.yearsOfExperience} yrs', Colors.black),
                              _buildVetDetailCard(
                                  'Degree', vet.degree, Colors.black),
                              _buildVetDetailCard(
                                  'University', vet.university, Colors.black),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Connect Button
                      if (authProvider.petOwner != null)
                        Center(
                          child: ButtonWidget(
                            onPressed: () async {
                              //  return  ;
                              final chatService =
                                  ChatService(); // Instance of ChatService
                              final currentUserId = authProvider.petOwner?.id ??
                                  authProvider.vet?.id;
                     

                              if (currentUserId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'You must be logged in to start a chat.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final participantId =
                                  vet.id; // Replace with the actual vet's ID
                              final participantName =
                                  vet.name; // Replace with the vet's name
                              final participantImageUrl = vet.imageUrl ??
                                  ''; // Replace with the vet's image URL

                              try {
                                // Check if a chat already exists
                                final existingChat = await FirebaseFirestore
                                    .instance
                                    .collection('Chats')
                                    .where('participants',
                                        arrayContains: currentUserId)
                                    .get();

                                String? chatId;

                                try {
                                  final chat = existingChat.docs.firstWhere(
                                    (doc) => (doc.data()['participants']
                                            as List<dynamic>)
                                        .contains(participantId),
                                  );

                                  chatId = chat.id; // Use the existing chat ID
                                } catch (e) {
                                  // Create a new chat if no existing chat is found
                                  chatId = await chatService.createChat(
                                      [currentUserId, participantId]);
                                }

                                // Navigate to the Chat Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatId: chatId!,
                                      participantName: participantName,
                                      participantImageUrl: participantImageUrl,
                                      type: 'vet',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                print('Failed to initialize chat: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Failed to start chat. Please try again later.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            text: 'Chat with Vet',
                            icon: const Icon(
                              Icons.message_outlined,
                              size: 24,
                              color: Colors.white,
                            ),
                            options: ButtonOptions(
                              height: 50.0,
                              width: MediaQuery.of(context).size.width * 0.7,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              color: Theme.of(context).primaryColor,
                              textStyle:
                                  appTheme.of(context).titleMedium.override(
                                        fontFamily: 'Inter Tight',
                                        color: Colors.white,
                                        letterSpacing: 0.0,
                                      ),
                              borderRadius: BorderRadius.circular(20),
                              iconSize: 24.0,
                              iconColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
      ),
    );
  }

  static Widget _buildContactInfo(
      BuildContext context, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not available',
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildVetDetailCard(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}

Widget _buildSectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
    ),
  );
}

Widget _buildVetDetailCard(String label, String value, Color color) {
  return Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.black),
        ),
      ],
    ),
  );
}

Widget _buildContactInfo(BuildContext context, String label, String? value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        '$label:',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
      ),
      Text(
        value ?? 'Not available',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}

class MedicalDocumentsSection extends StatefulWidget {
  final Pet pet;

  const MedicalDocumentsSection({required this.pet, Key? key})
      : super(key: key);

  @override
  _MedicalDocumentsSectionState createState() =>
      _MedicalDocumentsSectionState();
}

class _MedicalDocumentsSectionState extends State<MedicalDocumentsSection> {
  bool isExpandedDocuments = false;
  bool isUploading = false;
  List<Map<String, String>> documents = [];

  @override
  void initState() {
    super.initState();
    documents = widget.pet.documents; // Initialize with current pet documents
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'], // Allowed file types
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      setState(() {
        isUploading = true; // Show loading indicator during upload
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

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('pets')
            .doc(widget.pet.id)
            .update({
          'documents': FieldValue.arrayUnion([documentData])
        });

        // Update local state
        setState(() {
          documents.add(documentData); // Add the document to the local list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document uploaded: $fileName')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload document: $e'),
          ),
        );
      } finally {
        setState(() {
          isUploading = false; // Hide loading indicator
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No document selected.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsToShow =
        isExpandedDocuments ? documents : documents.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, 'Medical Documents'),
            IconButton(
              icon: isUploading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : Icon(
                      Icons.add,
                      color: Theme.of(context).primaryColor,
                    ),
              onPressed: isUploading
                  ? null // Disable the button while uploading
                  : () async {
                      await _uploadDocument();
                    },
            ),
          ],
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: documents.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: documentsToShow.length,
                        itemBuilder: (context, index) {
                          final document = documentsToShow[index];
                          return ListTile(
                            leading: Icon(
                              Icons.insert_drive_file,
                              color: Theme.of(context).primaryColor,
                            ),
                            title: Text(
                              document['name']!,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
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
                                    mode: LaunchMode
                                        .externalApplication, // Open in an external application
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
                          );
                        },
                      ),
                      if (documents.length > 3)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isExpandedDocuments = !isExpandedDocuments;
                            });
                          },
                          child: Text(
                            isExpandedDocuments ? 'View Less' : 'View More',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Text(
                      'No medical documents available.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
