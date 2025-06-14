import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'pet_class.dart';

class Vet {
  String id;
  String name;
  String bio;
  String email;
  String phone;
  String location;
  double yearsOfExperience;
  String degree;
  String university;
  List<String> specializations; // Vet's specializations
  List<Pet> patients; // Dynamically fetched list of Pet objects
  String? imageUrl; // Profile image URL

  Logger logger = Logger();

  Vet({
    required this.id,
    required this.name,
    required this.bio,
    required this.email,
    required this.phone,
    required this.location,
    required this.yearsOfExperience,
    required this.degree,
    required this.university,
    required this.specializations,
    required this.patients,
    this.imageUrl,
  });

  // Convert a Vet object into a map for Firestore (storing only pet IDs)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'email': email,
      'phone': phone,
      'location': location,
      'yearsOfExperience': yearsOfExperience,
      'degree': degree,
      'university': university,
      'specializations': specializations, // Save specializations
      'patientPetIds': patients.map((pet) => pet.id).toList(), // Save only pet IDs
      'profileImageUrl': imageUrl,
    };
  }

  // Create a Vet object from a Firestore map
  factory Vet.fromMap(Map<String, dynamic> map, String documentId) {
    return Vet(
      id: documentId,
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      yearsOfExperience: (map['yearsOfExperience'] ?? 0).toDouble(),
      degree: map['degree'] ?? '',
      university: map['university'] ?? '',
      specializations: List<String>.from(map['specializations'] ?? []),
      patients: [], // Patients will be populated dynamically later
      imageUrl: map['profileImageUrl'],
    );
  }

  // Save the Vet profile to Firestore
  Future<bool> saveToFirestore({
    int retries = 3,
    Duration delay = const Duration(seconds: 3),
  }) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final collection = FirebaseFirestore.instance.collection('vets');
        final docRef = collection.doc(id);

        if ((await docRef.get()).exists) {
          await docRef.update(toMap());
        } else {
          await docRef.set(toMap());
        }
        return true;
      } catch (e) {
        logger.d("Error saving to Firebase (attempt ${attempt + 1}): $e");
        if (attempt < retries - 1) {
          await Future.delayed(delay * (attempt + 1)); // Exponential backoff
        } else {
          return false;
        }
      }
    }
    return false;
  }

  // Fetch a Vet from Firestore and populate their patients dynamically
  static Future<Vet?> fetchFromFirestore(String documentId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('vets')
        .doc(documentId)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      final vet = Vet.fromMap(data, docSnapshot.id);

      // Fetch patients based on IDs stored in Firestore
      final petIds = List<String>.from(data['patientPetIds'] ?? []);
      final pets = await _fetchPetsByIds(petIds);

      vet.patients.addAll(pets); // Populate the patients list
      return vet;
    }
    return null;
  }

  // Fetch pets by their IDs from Firestore
  static Future<List<Pet>> _fetchPetsByIds(List<String> petIds) async {
    if (petIds.isEmpty) return [];
    final querySnapshot = await FirebaseFirestore.instance
        .collection('pets')
        .where(FieldPath.documentId, whereIn: petIds)
        .get();

    final foundPetIds = querySnapshot.docs.map((doc) => doc.id).toList();
    final missingPetIds = petIds.where((id) => !foundPetIds.contains(id)).toList();

    // Remove missing pets from Firestore and Vet's pet list
    for (String missingId in missingPetIds) {
      await FirebaseFirestore.instance.collection('pets').doc(missingId).delete();
      petIds.remove(missingId);
    }

    return querySnapshot.docs
        .map((doc) => Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Create a Vet object from form inputs
  static Vet fromForm({
    required String id,
    required String name,
    required String bio,
    required String email,
    required String phone,
    required String location,
    required double yearsOfExperience,
    required String degree,
    required String university,
    required List<String> specializations,
    String? imageUrl,
  }) {
    return Vet(
      id: id,
      name: name,
      bio: bio,
      email: email,
      phone: phone,
      location: location,
      yearsOfExperience: yearsOfExperience,
      degree: degree,
      university: university,
      specializations: specializations,
      patients: [], // Initially empty list of patients
      imageUrl: imageUrl,
    );
  }
}
