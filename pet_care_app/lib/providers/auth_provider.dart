import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:pet_care_app/firebase/pet_owner_class.dart';
import 'package:pet_care_app/firebase/vet_class.dart';
import '../services/auth_service.dart';
import 'app_state_notifier.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final AppStateNotifier appStateNotifier;
  final logger = Logger();

  PetOwner? _petOwner;
  PetOwner? get petOwner => _petOwner;
  set petOwner(PetOwner? value) {
    _petOwner = value;
    notifyListeners();
  }

  Vet? _vet;
  Vet? get vet => _vet;
  set vet(Vet? value) {
    _vet = value;
    notifyListeners();
  }

  User? _user;
  User? get user => _user;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileListener;
  StreamSubscription? _petsListener;

  AuthProvider({required this.appStateNotifier}) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
    checkLoginState().then((isLoggedIn) {
      if (isLoggedIn) {
        logger.d('User is logged in based on saved token.');
        // Restore user state or re-authenticate if necessary
      } else {
        logger.d('No saved login state found.');
      }
    });
    logger.d('AuthProvider initialized');
  }

  /// Start listening for Firestore changes for PetOwner or Vet

  void listenToProfileUpdates(String userId, String role) {
    _profileListener?.cancel(); // Cancel existing profile listener

    final collectionName = role == 'vet' ? 'vets' : 'pet_owners';

    _profileListener = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(userId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        if (role == 'vet') {
          final updatedVet = Vet.fromMap(snapshot.data()!, snapshot.id);
          final petIds =
              List<String>.from(snapshot.data()?['patientPetIds'] ?? []);
          updatedVet.patients = await _fetchPetsByIds(petIds);

          _vet = updatedVet;
          _petOwner = null; // Clear PetOwner data

          listenToPets(petIds); // Start listening to pets updates
          logger.d('Vet profile updated in real-time: ${updatedVet.name}');
        } else {
          final updatedOwner = PetOwner.fromMap(snapshot.data()!, snapshot.id);
          final petIds = List<String>.from(snapshot.data()?['petIds'] ?? []);
          updatedOwner.pets = await _fetchPetsByIds(petIds);

          _petOwner = updatedOwner;
          _vet = null; // Clear Vet data

          listenToPets(petIds); // Start listening to pets updates
          logger.d(
              'PetOwner profile updated in real-time: ${updatedOwner.name}, Pets: ${updatedOwner.pets.length}');
        }
        notifyListeners();
      }
    });
  }

  void listenToPets(List<String> petIds) {
    logger.d('listenToPets called with petIds: $petIds');

    // Cancel existing listener to avoid duplication
    if (_petsListener != null) {
      logger.d('Cancelling existing _petsListener.');
      _petsListener!.cancel();
      _petsListener = null;
    }

    // If petIds is empty, log and exit
    if (petIds.isEmpty) {
      logger.d('No pets to listen to. Exiting listenToPets.');
      return;
    }

    // Check if petIds exceed Firestore's whereIn limit
    if (petIds.length > 10) {
      logger
          .w('Pet IDs exceed Firestore whereIn limit. Splitting into batches.');

      // Process the list in batches
      List<Future<void>> batchListeners = [];
      for (int i = 0; i < petIds.length; i += 10) {
        final batch =
            petIds.sublist(i, i + 10 > petIds.length ? petIds.length : i + 10);
        batchListeners.add(_setupPetsListener(batch));
      }

      Future.wait(batchListeners).then((_) {
        logger.d('All batch listeners set up successfully.');
      }).catchError((error) {
        logger.e('Error setting up batch listeners: $error');
      });

      return;
    }

    // Proceed with a single listener if petIds are within limits
    _setupPetsListener(petIds);
  }

  Future<void> _setupPetsListener(List<String> petIds) async {
    try {
      logger.d('Setting up Firestore listener for pets batch: $petIds');
      _petsListener = FirebaseFirestore.instance
          .collection('pets')
          .where(FieldPath.documentId, whereIn: petIds)
          .snapshots()
          .listen(
        (snapshot) {
          logger.d('Snapshot received with ${snapshot.docs.length} documents.');
          try {
            final updatedPets = snapshot.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null) {
                    logger.w(
                        'Document with id ${doc.id} has null data. Skipping.');
                    return null;
                  }
                  return Pet.fromMap(data, doc.id);
                })
                .whereType<Pet>()
                .toList();

            if (_petOwner != null) {
              logger.d('Updating pets for PetOwner.');
              _petOwner!.pets = updatedPets;

              // ✅ CHANGE: Repopulate the petOwner's events from all pets
              List<Map<String, dynamic>> combinedEvents = [];

              for (var pet in updatedPets) {
                combinedEvents.addAll(pet.events);
                combinedEvents.addAll(pet.vetEvents);
              }

              // Now assign the combined list using the setter
              _petOwner!.events = combinedEvents;

              //  notifyListeners();
              // ✅ CHANGE: Save the updated events back to Firestore
              // FirebaseFirestore.instance
              //     .collection('pet_owners')
              //     .doc(_petOwner!.id)
              //     .update({'events': _petOwner!.events});
            } else if (_vet != null) {
              logger.d('Updating patients for Vet.');
              _vet!.patients = updatedPets;
            }

            notifyListeners();
            logger.d('Listeners notified of pet updates.');
          } catch (e) {
            logger.e('Error processing snapshot: $e');
          }
        },
        onError: (error) {
          logger.e('Error listening to pets: $error');
        },
      );

      logger.d('Pets listener successfully set up for batch: $petIds');
    } catch (e) {
      logger.e('Failed to set up pets listener: $e');
    }
  }

// Fetch pets by their IDs from Firestore
  Future<List<Pet>> _fetchPetsByIds(List<String> petIds) async {
    if (petIds.isEmpty) return [];
    try {
      // Fetch each pet using Pet.fetchFromFirestore
      final pets = await Future.wait(
        petIds.map((id) => Pet.fetchFromFirestore(id)),
      );

      // Filter out any null results (in case a pet ID doesn't exist)
      return pets.whereType<Pet>().toList();
    } catch (e) {
      logger.e('Error fetching pets: $e');
      return [];
    }
  }

  /// Handle auth state changes
  void _onAuthStateChanged(User? user) async {
    _user = user;
    appStateNotifier.updateUser(user);

    if (user != null) {
      // Determine the role of the user (vet or pet owner)
      final role = await _fetchUserRole(user.uid);

      if (role != null) {
        listenToProfileUpdates(user.uid, role);
      } else {
        logger.e('Role not found for user: ${user.uid}');
      }
    } else {
      // Clear profile data when user logs out
      _clearState();
    }

    notifyListeners();
  }

  void _clearState() {
    _profileListener?.cancel();
    _petsListener?.cancel();
    _petOwner = null;
    _vet = null;
  }

  /// Fetch user role from Firestore
  Future<String?> _fetchUserRole(String userId) async {
    try {
      final petOwnerDoc = await FirebaseFirestore.instance
          .collection('pet_owners')
          .doc(userId)
          .get();
      if (petOwnerDoc.exists) {
        return 'pet_owner';
      }

      final vetDoc =
          await FirebaseFirestore.instance.collection('vets').doc(userId).get();
      if (vetDoc.exists) {
        return 'vet';
      }

      logger.e(
          'if using google its okay :p,Role not found for user: ${_user!.uid}');

      return null;
    } catch (e) {
      logger.e('Failed to fetch user role: $e');
      return null;
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      appStateNotifier.updateUser(_user);
      logger.d('User signed in: ${_user?.uid}');

      if (_user != null) {
        final role = await _fetchUserRole(_user!.uid);
        if (role != null) {
          if (role == 'vet') {
            final vet = await Vet.fetchFromFirestore(_user!.uid);
            _vet = vet;
          } else {
            final petOwner = await PetOwner.fetchFromFirestore(_user!.uid);
            _petOwner = petOwner;
            print('pet owner pets ${petOwner?.pets.length}');
          }
          listenToProfileUpdates(_user!.uid, role);
        }
        await appStateNotifier.saveDeviceToken(_user!.uid);
      }
      saveLoginState(_user!.uid);
      notifyListeners();
    } catch (e) {
      logger.e('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> saveLoginState(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token); // Save token
  }

  Future<bool> checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken'); // Retrieve saved token

    if (token != null) {
      _user = FirebaseAuth.instance.currentUser;

      if (_user != null) {
        final role = await _fetchUserRole(_user!.uid);
        if (role != null) {
          if (role == 'vet') {
            final vet = await Vet.fetchFromFirestore(_user!.uid);
            _vet = vet;
          } else {
            final petOwner = await PetOwner.fetchFromFirestore(_user!.uid);
            _petOwner = petOwner;
          }
          listenToProfileUpdates(_user!.uid, role);
          appStateNotifier.updateUser(_user);
          return true;
        }
      }
    }
    return false;
  }

  /// Sign up with email and password
  Future<void> signUp(String email, String password, String role) async {
    try {
      _user = await _authService.registerWithEmailAndPassword(email, password);
      appStateNotifier.updateUser(_user);
      logger.d('User signed up: ${_user?.uid}');
      if (_user != null) {
        // Create an initial profile based on the role
        listenToProfileUpdates(_user!.uid, role);
        await appStateNotifier.saveDeviceToken(_user!.uid);
      }
      notifyListeners();
    } catch (e) {
      logger.e('Error signing up: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    // Reset the deviceToken in Firestore
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'deviceToken': FieldValue.delete()});
    }

    await _authService.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove('authToken');
    appStateNotifier.updateUser(null);

    _clearState();
    logger.d('User signed out, device token reset, and login state cleared');
    notifyListeners();
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      // Sign out any existing session if necessary
      if (await _authService.googleSignIn.isSignedIn()) {
        await _authService.googleSignIn.signOut();
      }

      // Perform Google Sign-In
      final UserCredential userCredential =
          await _authService.signInWithGoogle();

      if (userCredential.user == null) {
        throw Exception('Google Sign-In failed. User is null.');
      }

      _user = userCredential.user;

      // Check if the user is new
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      logger.d('User signed in: ${_user?.uid}');
      if (_user != null) {
        appStateNotifier.updateUser(_user);

        if (isNewUser) {
          logger.d('Assigning default role for new user: ${_user!.uid}');
        } else {
          // Fetch the existing role for the user
          final role = await _fetchUserRole(_user!.uid);

          if (role == null) {
            logger.e('User role not found. Deleting account.');
            await deleteAccount(); // Ensure account is deleted
            _user = null;
            appStateNotifier.updateUser(null);
            return false;
          }

          logger.d('User role found: $role');
          if (role == 'vet') {
            _vet = await Vet.fetchFromFirestore(_user!.uid);
          } else if (role == 'pet_owner') {
            _petOwner = await PetOwner.fetchFromFirestore(_user!.uid);
          }

          listenToProfileUpdates(_user!.uid, role);
        }

        // Save the device token if the user exists
        if (_user != null) {
          await appStateNotifier.saveDeviceToken(_user!.uid);
        }
      }

      notifyListeners();
      return isNewUser;
    } catch (e) {
      logger.e('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (_user == null) {
      logger.w('No user signed in. Cannot delete account.');
      return;
    }

    try {
      final userId = _user!.uid;

      // Delete user from authentication
      await _authService.deleteAccount();

      // Check and delete from pet_owners collection
      final petOwnerDoc = await FirebaseFirestore.instance
          .collection('pet_owners')
          .doc(userId)
          .get();
      if (petOwnerDoc.exists) {
        await petOwnerDoc.reference.delete();
        logger.d('PetOwner profile deleted: $userId');
      } else {
        logger.w('No PetOwner profile found for user: $userId');
      }

      // Check and delete from vets collection
      final vetDoc =
          await FirebaseFirestore.instance.collection('vets').doc(userId).get();
      if (vetDoc.exists) {
        await vetDoc.reference.delete();
        logger.d('Vet profile deleted: $userId');
      } else {
        logger.w('No Vet profile found for user: $userId');
      }

      // Clear state after successful deletion
      _clearState();
      logger.d('User account deleted successfully');
      notifyListeners();
    } catch (e) {
      logger.e('Error deleting account: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    logger.d('Disposing AuthProvider and cancelling listeners.');
    _profileListener?.cancel();
    _petsListener?.cancel();
    super.dispose();
  }
}
