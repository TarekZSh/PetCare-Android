import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'pet_class.dart';
import 'package:logger/logger.dart';

class PetOwner {
  String id;
  String name;
  String bio;
  String phoneNumber;
  String birthDay;
  String? imageUrl; // Optional image URL
  List<Pet> pets; // List of pets associated with the owner
  final List<Map<String, dynamic>> _events;

  List<Map<String, dynamic>> get events => _events;

  // ✅ Public setter for events (this is important for modification)
  set events(List<Map<String, dynamic>> updatedEvents) {
    _events
      ..clear()
      ..addAll(updatedEvents);
  }


  PetOwner({
    required this.id,
    required this.name,
    required this.bio,
    required this.phoneNumber,
    required this.birthDay,
    this.imageUrl, // Optional image URL
    required this.pets,
  })  : _events = [];

  // Convert a PetOwner object into a map for Firestore (storing only pet IDs)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'birthDay': birthDay,
      'imageUrl': imageUrl, // Include image URL in the map
      'petIds': pets.map((pet) => pet.id).toList(), // Only save pet IDs

    };
  }

  // Create a PetOwner object from a Firestore map
  factory PetOwner.fromMap(Map<String, dynamic> map, String documentId) {
    return PetOwner(
      id: documentId,
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      birthDay: map['birthDay'] ?? '',
      imageUrl: map['imageUrl'], // Retrieve the image URL from Firestore
      pets: [], // Pets will be populated dynamically later
    );
  }

  // Save the profile to Firestore
  Future<bool> saveToFirestore({
    int retries = 3,
    Duration delay = const Duration(seconds: 3),
  }) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final collection = FirebaseFirestore.instance.collection('pet_owners');
        final docRef = collection.doc(id);

        if ((await docRef.get()).exists) {
          await docRef.update(toMap());
        } else {
          await docRef.set(toMap());
        }
        return true;
      } catch (e) {
        print("Error saving to Firebase (attempt ${attempt + 1}): $e");
        if (attempt < retries - 1) {
          await Future.delayed(delay * (attempt + 1)); // Exponential backoff
        } else {
          return false;
        }
      }
    }
    return false;
  }

  // Fetch a PetOwner from Firestore and populate their pets dynamically
  static Future<PetOwner?> fetchFromFirestore(String documentId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('pet_owners')
        .doc(documentId)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      final petOwner = PetOwner.fromMap(data, docSnapshot.id);

      // Fetch pets based on IDs stored in Firestore
      final petIds = List<String>.from(data['petIds'] ?? []);
      final pets = await _fetchPetsByIds(petIds);

      petOwner.pets.addAll(pets);
      for (var pet in pets) {
        petOwner.events.addAll(pet.events);
        petOwner.events.addAll(pet.vetEvents);

      }
      Logger logger = Logger();
      logger.i(petOwner.events);
      return petOwner;
    }
    return null;
  }

  // Fetch pets by their IDs from the pets collection
  static Future<List<Pet>> _fetchPetsByIds(List<String> petIds) async {
    if (petIds.isEmpty) return [];
    final querySnapshot = await FirebaseFirestore.instance
        .collection('pets')
        .where(FieldPath.documentId, whereIn: petIds)
        .get();

    return querySnapshot.docs
        .map((doc) => Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Create a PetOwner object from form inputs
  static PetOwner fromForm({
    required String id,
    required String name,
    required String bio,
    required String phoneNumber,
    required String birthDay,
    String? imageUrl,
  }) {
    return PetOwner(
      id: id,
      name: name,
      bio: bio,
      phoneNumber: phoneNumber,
      birthDay: birthDay,
      imageUrl: imageUrl,
      pets: [], 
      // Initially empty list of pets
    );
  }
}
