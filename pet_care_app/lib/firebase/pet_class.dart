import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:logger/logger.dart';

class Pet {
  String id;
  String ownerId;
  String name;
  String species;
  String gender;
  String breed;
  double weight;
  double height;
  double age;
  String owner;
  String bio;
  String? imageUrl;
  DateTime? birthDate;
  List<Map<String, String>> specialNotes; // Notes with key-value pairs
  List<String> lastActivities; // List of recent activities
  List<Map<String, String>>
      medicalHistory; // Medical history: title, date, doctor
  List<Map<String, String>> vaccinations; // Vaccination history
  List<Map<String, dynamic>> events; // Events added by pet owner
  List<Map<String, dynamic>> vetEvents; // Events added by vet
  List<Map<String, String>> documents; // List of document links (name, URL)
  Map<String, bool> preferences;

  final Logger logger = Logger();

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.gender,
    required this.breed,
    required this.weight,
    required this.height,
    required this.age,
    required this.owner,
    required this.bio,
    this.imageUrl,
    this.birthDate,
    required this.specialNotes,
    required this.lastActivities,
    required this.medicalHistory,
    required this.vaccinations,
    required this.events,
    required this.vetEvents,
    required this.documents,
    this.preferences = const {},
  });

  // Convert a Pet object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'species': species,
      'gender': gender,
      'breed': breed,
      'weight': weight,
      'height': height,
      'age': age,
      'owner': owner,
      'bio': bio,
      'imageUrl': imageUrl,
      'birthDate': birthDate?.toIso8601String(),
      'specialNotes': specialNotes,
      'lastActivities': lastActivities,
      'medicalHistory': medicalHistory,
      'vaccinations': vaccinations,
      'events': events,
      'vetEvents': vetEvents,
      'documents': documents, // Include document links
      'preferences': preferences,
    };
  }

  // Create a Pet object from a Firestore map
  factory Pet.fromMap(Map<String, dynamic> map, String documentId) {
    return Pet(
      id: documentId,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      gender: map['gender'] ?? '',
      breed: map['breed'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      age: (map['age'] as num?)?.toDouble() ?? 0.0,
      owner: map['owner'] ?? '',
      bio: map['bio'] ?? '',
      imageUrl: map['imageUrl'],
      birthDate:
          map['birthDate'] != null ? DateTime.tryParse(map['birthDate']) : null,
      specialNotes: (map['specialNotes'] as List<dynamic>? ?? [])
          .map((note) => Map<String, String>.from(note))
          .toList(),
      lastActivities: List<String>.from(map['lastActivities'] ?? []),
      medicalHistory: (map['medicalHistory'] as List<dynamic>? ?? [])
          .map((entry) => Map<String, String>.from(entry))
          .toList(),
      vaccinations: (map['vaccinations'] as List<dynamic>? ?? [])
          .map((entry) => Map<String, String>.from(entry))
          .toList(),
      events: List<Map<String, dynamic>>.from(map['events'] ?? []),
      vetEvents: List<Map<String, dynamic>>.from(map['vetEvents'] ?? []),
      documents: (map['documents'] as List<dynamic>? ?? [])
          .map((doc) => Map<String, String>.from(doc))
          .toList(),
      preferences: Map<String, bool>.from(map['preferences'] ?? {}),
    );
  }

  // Save the pet profile to Firestore
  Future<bool> saveToFirestore({
    int retries = 3,
    Duration delay = const Duration(seconds: 3),
  }) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final collection = FirebaseFirestore.instance.collection('pets');
        final docRef = collection.doc(id);

        if ((await docRef.get()).exists) {
          await docRef.update(toMap());
        } else {
          await docRef.set(toMap());
        }
        return true;
      } catch (e) {
        logger.e("Error saving to Firebase (attempt ${attempt + 1}): $e");
        if (attempt < retries - 1) {
          await Future.delayed(delay * (attempt + 1));
        } else {
          return false;
        }
      }
    }
    return false;
  }

  // Fetch a Pet profile from Firestore
  static Future<Pet?> fetchFromFirestore(String documentId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('pets')
        .doc(documentId)
        .get();

    if (docSnapshot.exists) {
      return Pet.fromMap(docSnapshot.data()!, docSnapshot.id);
    }
    return null;
  }

  Future<bool> updateToFirestore({
    int retries = 3,
    Duration delay = const Duration(seconds: 3),
    bool createIfNotExists = false, // New parameter
  }) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final collection = FirebaseFirestore.instance.collection('pets');
        final docRef = collection.doc(id);

        // Check if the document exists
        Logger().i("Checking if pet with id '$id' exists...");
        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          if (createIfNotExists) {
            Logger().i("Pet with id '$id' does not exist. Creating...");
            Logger().i("Data being sent: ${toMap()}");
            await docRef.set(toMap()); // Create the document if allowed
            Logger().i("Pet with id '$id' created successfully.");
            return true;
          } else {
            throw Exception("Pet with id '$id' does not exist. Cannot update.");
          }
        }

        // Update the document
        Logger().i("Updating pet with id '$id'...");
        docRef.update(toMap());
        Logger().i("Pet with id '$id' updated successfully.");
        return true;
      } catch (e) {
        print("Error updating to Firebase (attempt ${attempt + 1}): $e");
        if (attempt < retries - 1) {
          await Future.delayed(delay * (attempt + 1)); // Exponential backoff
        } else {
          return false;
        }
      }
    }
    return false;
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Pet) return false;
    return id == other.id;
  }
}
