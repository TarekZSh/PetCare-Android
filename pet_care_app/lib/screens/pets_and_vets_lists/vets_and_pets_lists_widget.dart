import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_care_app/common/base_model.dart';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:pet_care_app/firebase/vet_class.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/chat/chat_screen.dart';
import 'package:pet_care_app/screens/pets_and_vets_lists/detailed_view.dart';
import 'package:pet_care_app/services/chat_service.dart';
import 'package:provider/provider.dart';
import '/common/app_theme.dart';
import '/common/choice_chips_widget.dart';
import '/common/form_field_controller.dart';

import 'vets_and_pets_lists_model.dart';
export 'vets_and_pets_lists_model.dart';

class VetsandpetslistsWidget extends StatefulWidget {
  const VetsandpetslistsWidget({super.key});

  @override
  State<VetsandpetslistsWidget> createState() => _VetsandpetslistsWidgetState();
}

class _VetsandpetslistsWidgetState extends State<VetsandpetslistsWidget> {
  late VetsandpetslistsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Pet> _pets = [];
  List<Vet> _vets = [];
  String _selectedCategory = 'Pets';
  bool _isLoading = true;

  String _selectedGender = 'All';
  String _selectedSpecies = 'All';
  String _selectedSpecialization = 'All';
  String _selectedPreference = 'All';

  final Map<String, bool> preferences = {
     'All': false,
    'Open to Walk': false,
    'Open to Breed': false,
    'Open to Play': false,
    'Open to Socialize': false,
  };

  final List<String> genders = ['All', 'Male', 'Female', 'Other'];
  final List<String> speciesList = [
    'All',
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

  final List<String> specializationsList = [
    'All',
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
  String userType = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VetsandpetslistsModel());
    _model.textController ??= TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    userType = authProvider.petOwner != null ? 'Pet Owner' : 'Vet';

    _fetchData(); // Fetch data from Firebase
  }

  Future<void> _fetchData() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final petsSnapshot =
          await FirebaseFirestore.instance.collection('pets').get();
      final vetsSnapshot =
          await FirebaseFirestore.instance.collection('vets').get();

      final pets = petsSnapshot.docs
          .map((doc) => Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      final vets = vetsSnapshot.docs
          .map((doc) => Vet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (mounted) {
        setState(() {
          _pets = pets;
          _vets = vets;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> _getFilteredItems() {
    final query = _model.textController?.text.toLowerCase() ?? '';
    final items = _selectedCategory == 'Pets' ? _pets : _vets;

    return items.where((item) {
      final name = (item is Pet ? item.name : (item as Vet).name).toLowerCase();

      // Filter by name
      if (!name.contains(query)) return false;

      // Additional filters for pets
      if (item is Pet) {
        if (_selectedGender != 'All' && item.gender != _selectedGender) {
          return false;
        }
        if (_selectedSpecies != 'All' && item.species != _selectedSpecies) {
          return false;
        }
        if (_selectedPreference != 'All') {
        // Check if the selected preference is true for the pet
        if (!item.preferences.containsKey(_selectedPreference) ||
            !item.preferences[_selectedPreference]!) {
          return false;
        }
      }
    
      }

      // Additional filters for vets
      if (item is Vet) {
        if (_selectedSpecialization != 'All' &&
            !item.specializations.contains(_selectedSpecialization)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

Widget _buildList() {
  if (_isLoading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  final items = _getFilteredItems();

  if (items.isEmpty) {
    return Center(
      child: Text(
        'No results found',
        style: appTheme.of(context).bodyLarge.override(
              fontFamily: 'Inter',
              color: Colors.grey,
            ),
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: _fetchData,
    child: ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = items[index]; // Get the filtered item
        final cardColor = item is Pet
            ? (index % 2 == 0
                ? const Color(0xFFE8F5E9) // Light Green for Pets
                : const Color(0xFFE3F2FD)) // Light Blue for Pets
            : (index % 2 == 0
                ? const Color(0xFFFFF3E0) // Light Yellow for Vets
                : const Color(0xFFFFE0B2)); // Light Peach for Vets

        // Pass item.id instead of index
        return _buildListItem(item, cardColor, index);
      },
    ),
  );
}

Widget _buildListItem(dynamic item, Color cardColor, int index) {
  final isPet = item is Pet;
  final imageUrl = item.imageUrl ?? '';
  final name = item.name;
  final subtitle = isPet
      ? item.bio ?? 'No bio available'
      : item.specializations.join(', ') ?? 'No specializations';

  // Determine if the item is a patient of the vet
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  bool isVetPatient = false;
  if (authProvider.vet != null && isPet) {
    isVetPatient =
        authProvider.vet!.patients.any((patient) => patient.id == item.id);
  }

  return GestureDetector(
    onTap: () {
      // Open the appropriate modal for pet or vet
      if (isPet) {
        PetDetailModal.show(
          context,
          item,
          index, // Use the unique identifier instead of index
          onUpdate: () {
            setState(() {
              debugPrint("onUpdate called");
              // Update isVetPatient dynamically based on the modal changes
              isVetPatient = authProvider.vet!.patients
                  .any((patient) => patient.id == item.id);
            });
          },
        );
      } else if (item is Vet) {
        VetDetailModal.show(context, item, index); // Use the unique identifier
      }
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16), // Increased spacing
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16), // Larger radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 40, // Larger profile picture
              backgroundImage: (imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl)
                  : isPet
                      ? const AssetImage('assets/images/PetProfilePicture.png')
                          as ImageProvider
                      : const AssetImage('assets/images/vetProfile.png')
                          as ImageProvider,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 16), // Space between image and details
            // Details Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: appTheme.of(context).headlineMedium.override(
                          fontFamily: 'Inter Tight',
                          color: isPet
                              ? appTheme.of(context).success
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // For Pet
                  if (isPet) ...[
                    _buildColoredDetail(
                        'Species: ', item.species, Colors.blue),
                    _buildColoredDetail('Age: ',
                        '${item.age.toStringAsFixed(1)} years', Colors.teal),
                    _buildColoredDetail(
                        'Gender: ', item.gender ?? 'Unknown', Colors.purple),
                    const SizedBox(height: 4),
                    Text(
                      item.bio ?? 'No bio available',
                      style: appTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            color: appTheme.of(context).secondaryText,
                          ),
                    ),
                  ],
                  // For Vet
                  if (!isPet) ...[
                    _buildColoredDetail('Specializations: ',
                        item.specializations.join(', '), Colors.blue),
                    _buildColoredDetail('Location: ',
                        item.location ?? 'Unknown', Colors.green),
                    const SizedBox(height: 4),
                    Text(
                      item.bio ?? 'No bio available',
                      style: appTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            color: appTheme.of(context).secondaryText,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            userActions(
                context, _selectedCategory, item.id, () => setState(() {})),
          ],
        ),
      ),
    ),
  );
}

  Widget userActions(
    BuildContext context,
    String choiceChipsValue,
    String itemId,
    Function onStateChange,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String userType = authProvider.petOwner != null ? 'Pet Owner' : 'Vet';
    final currentUserId = authProvider.petOwner?.id ?? authProvider.vet?.id;

    // Handle choice chip value for "Veterinarians"
    if (choiceChipsValue == 'Veterinarians') {
      if (userType == 'Pet Owner') {
        return IconButton(
          icon: const Icon(Icons.chat, color: Colors.grey, size: 24),
          onPressed: () async {
             // return  ;
            final chatService = ChatService();

            if (currentUserId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You must be logged in to start a chat.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Assuming veterinarian details are fetched based on the index
            final Vet vet =
                _vets.firstWhere((v) => v.id == itemId); // Replace `_vets` with your actual data source
            final participantId = vet.id;
            final participantName = vet.name;
            final participantImageUrl =
                vet.imageUrl ?? ''; // Fetch from Firestore if needed

            try {
              // Check if a chat already exists
              final existingChat = await FirebaseFirestore.instance
                  .collection('Chats')
                  .where('participants', arrayContains: currentUserId)
                  .get();

              String? chatId;

              try {
                final chat = existingChat.docs.firstWhere(
                  (doc) => (doc.data()['participants'] as List<dynamic>)
                      .contains(participantId),
                );

                chatId = chat.id; // Use the existing chat ID
              } catch (e) {
                // Create a new chat if no existing chat is found
                chatId = await chatService
                    .createChat([currentUserId, participantId]);
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
                  content:
                      Text('Failed to start chat. Please try again later.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      } else if (userType == 'Vet') {
        // No special action required if the user is a Vet and viewing Veterinarians
        return const SizedBox.shrink();
      }
    }

    // Handle choice chip value for "Pets"
    if (choiceChipsValue == 'Pets') {
      if (userType == 'Vet') {
        final Pet pet =
            _pets.firstWhere((p) => p.id == itemId);; // Replace `_pets` with your actual data source
        final Vet vet = authProvider.vet!;
        bool isPatient = vet.patients.any((patient) => patient.id == pet.id);

        return StatefulBuilder(
          builder: (context, setState) {
            bool loading = false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat icon
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.grey, size: 24),
                  onPressed: () async {
                     // return  ;
                    final chatService = ChatService();

                    if (currentUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('You must be logged in to start a chat.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final participantId = pet.ownerId;
                    final participantName = pet.owner;
                    final participantImageUrl = await FirebaseFirestore.instance
                        .collection('pet_owners')
                        .doc(participantId)
                        .get()
                        .then((doc) => doc.data()?['imageUrl'] ?? '');

                    try {
                      // Check if a chat already exists
                      final existingChat = await FirebaseFirestore.instance
                          .collection('Chats')
                          .where('participants', arrayContains: currentUserId)
                          .get();

                      String? chatId;

                      try {
                        final chat = existingChat.docs.firstWhere(
                          (doc) => (doc.data()['participants'] as List<dynamic>)
                              .contains(participantId),
                        );

                        chatId = chat.id; // Use the existing chat ID
                      } catch (e) {
                        // Create a new chat if no existing chat is found
                        chatId = await chatService
                            .createChat([currentUserId, participantId]);
                      }

                      // Navigate to the Chat Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chatId!,
                            participantName: participantName,
                            participantImageUrl: participantImageUrl,
                            type: 'pet_owner',
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
                ),
                // Add/Remove icon with loading state
                IconButton(
                  icon: Icon(
                    isPatient
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: isPatient ? Colors.red : Colors.green,
                    size: 24,
                  ),
                  onPressed: loading
                      ? null // Disable button while loading
                      : () async {
                          if (mounted) {
                            setState(() {
                              loading = true; // Start loading
                            });
                          }

                          try {
                            if (isPatient) {
                              // Remove the pet from the vet's patient list
                              vet.patients.removeWhere(
                                  (patient) => patient.id == pet.id);
                              await vet.saveToFirestore();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${pet.name} removed from patient list'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              // Add the pet to the vet's patient list
                              vet.patients.add(pet);
                              await vet.saveToFirestore();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${pet.name} added to patient list'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }

                            // Check if the pet still exists in Firestore after the operation
                            FirebaseFirestore.instance
                                .collection('pets')
                                .doc(pet.id)
                                .get()
                                .then((doc) async {
                              if (!doc.exists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'This pet has been deleted and removed from your patients list.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );

                                // Remove the deleted pet from the vet's patient list
                                vet.patients.removeWhere(
                                    (patient) => patient.id == pet.id);
                                await vet.saveToFirestore();
                              }
                            });

                            // Notify parent to rebuild UI
                            onStateChange();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('An error occurred: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                loading = false; // End loading
                              });
                            }
                          }
                        },
                )
              ],
            );
          },
        );
      } else if (userType == 'Pet Owner') {
        final Pet pet =
            _pets.firstWhere((p) => p.id == itemId); // Replace `_pets` with your actual data source

        return IconButton(
          icon: const Icon(Icons.chat, color: Colors.grey, size: 24),
          onPressed: () async {
              //return  ;
            if (currentUserId == pet.ownerId) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You cannot chat with yourself.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            final chatService = ChatService();

            if (currentUserId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You must be logged in to start a chat.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final participantId = pet.ownerId;
            final participantName = pet.owner;
            final participantImageUrl = await FirebaseFirestore.instance
                .collection('pet_owners')
                .doc(participantId)
                .get()
                .then((doc) => doc.data()?['imageUrl'] ?? '');

            try {
              // Check if a chat already exists
              final existingChat = await FirebaseFirestore.instance
                  .collection('Chats')
                  .where('participants', arrayContains: currentUserId)
                  .get();

              String? chatId;

              try {
                final chat = existingChat.docs.firstWhere(
                  (doc) => (doc.data()['participants'] as List<dynamic>)
                      .contains(participantId),
                );

                chatId = chat.id; // Use the existing chat ID
              } catch (e) {
                // Create a new chat if no existing chat is found
                chatId = await chatService
                    .createChat([currentUserId, participantId]);
              }

              // Navigate to the Chat Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: chatId!,
                    participantName: participantName,
                    participantImageUrl: participantImageUrl,
                    type: 'pet_owner',
                  ),
                ),
              );
            } catch (e) {
              print('Failed to initialize chat: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Failed to start chat. Please try again later.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      }
    }

    // Default fallback
    return const SizedBox.shrink();
  }

  Future<void> _refreshPets() async {
    try {
      final petsSnapshot =
          await FirebaseFirestore.instance.collection('pets').get();

      final pets = petsSnapshot.docs
          .map((doc) => Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (mounted) {
        setState(() {
          _pets = pets; // Update the pets list
        });
      }
    } catch (e) {
      print('Error refreshing pets data: $e');
    }
  }

  /// Helper method to create a detail row with colored labels
  Widget _buildColoredDetail(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: appTheme.of(context).primaryBackground,
        body: Stack(
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
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.03,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 35),
                  _buildTitle(),
                  _buildSearchField(size),
                  _buildCategoryChips(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(16.0), // Add rounded corners
                      child: _buildList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Find Your Perfect Match',
      textAlign: TextAlign.center,
      style: appTheme.of(context).headlineMedium.override(
            fontFamily: 'Inter Tight',
            color: Colors.white,
            letterSpacing: 0.0,
          ),
    );
  }

  Widget _buildHorizontalSpeciesFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: speciesList.map((species) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(species),
              selected: _selectedSpecies == species,
              onSelected: (selected) {
                if (mounted) {
                  setState(() {
                    _selectedSpecies = selected ? species : 'All';
                  });
                }
              },
              selectedColor: appTheme.of(context).success,
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: _selectedSpecies == species
                    ? Colors.white
                    : appTheme.of(context).secondaryText,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreferencesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Preferences',
          style: appTheme.of(context).headlineSmall.override(
                fontFamily: 'Inter Tight',
                color: appTheme.of(context).primaryText,
                fontWeight: FontWeight.bold,
              ),
        ),
        
        const SizedBox(height: 8), 

        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: preferences.keys.map((preference) {
            return ChoiceChip(
              label: Text(preference),
              selected: _selectedPreference == preference,
              onSelected: (selected) {
                if (mounted) {
                  setState(() {
                    _selectedPreference = selected ? preference : 'All';
                  });
                }
              },
              selectedColor: appTheme.of(context).success,
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: _selectedPreference == preference
                    ? Colors.white
                    : appTheme.of(context).secondaryText,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    if (_selectedCategory == 'Pets') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gender Filter
          Text(
            'Filter by Gender',
            style: appTheme.of(context).headlineSmall.override(
                  fontFamily: 'Inter Tight',
                  color: appTheme.of(context).primaryText,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: genders.map((gender) {
              return ChoiceChip(
                label: Text(gender),
                selected: _selectedGender == gender,
                onSelected: (selected) {
                  if (mounted) {
                    setState(() {
                      _selectedGender = selected ? gender : 'All';
                    });
                  }
                },
                selectedColor: appTheme.of(context).success,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: _selectedGender == gender
                      ? Colors.white
                      : appTheme.of(context).secondaryText,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Preferences Filter
          _buildPreferencesFilter(),

          const SizedBox(height: 16),
          // Species Filter
          Text(
            'Filter by Species',
            style: appTheme.of(context).headlineSmall.override(
                  fontFamily: 'Inter Tight',
                  color: appTheme.of(context).primaryText,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildHorizontalSpeciesFilter(),
        ],
      );
    } else if (_selectedCategory == 'Veterinarians') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Specialization',
            style: appTheme.of(context).headlineSmall.override(
                  fontFamily: 'Inter Tight',
                  color: appTheme.of(context).primaryText,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: specializationsList.map((specialization) {
              return ChoiceChip(
                label: Text(specialization),
                selected: _selectedSpecialization == specialization,
                onSelected: (selected) {
                  if (mounted) {
                    setState(() {
                      _selectedSpecialization =
                          selected ? specialization : 'All';
                    });
                  }
                },
                selectedColor: appTheme.of(context).success,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: _selectedSpecialization == specialization
                      ? Colors.white
                      : appTheme.of(context).secondaryText,
                ),
              );
            }).toList(),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void showFilterModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double modalHeight = constraints.maxHeight * 0.8;

              return Container(
                height: modalHeight,
                width: constraints.maxWidth,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Filter Options',
                          style: appTheme.of(context).headlineMedium.override(
                                fontFamily: 'Inter Tight',
                                color: appTheme.of(context).success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_selectedCategory == 'Pets') ...[
                        // Gender Filter
                        Text(
                          'Filter by Gender',
                          style: appTheme.of(context).headlineSmall.override(
                                fontFamily: 'Inter Tight',
                                color: appTheme.of(context).success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: genders.map((gender) {
                            return ChoiceChip(
                              label: Text(gender),
                              selected: _selectedGender == gender,
                              onSelected: (selected) {
                                modalSetState(() {
                                  _selectedGender = selected ? gender : 'All';
                                });
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              selectedColor: appTheme.of(context).success,
                              backgroundColor: Colors.grey[200],
                              labelStyle: TextStyle(
                                color: _selectedGender == gender
                                    ? Colors.white
                                    : appTheme.of(context).secondaryText,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Preferences Filter
                        Text(
                          'Filter by Preferences',
                          style: appTheme.of(context).headlineSmall.override(
                                fontFamily: 'Inter Tight',
                                color: appTheme.of(context).success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: preferences.keys.map((preference) {
                            return ChoiceChip(
                              label: Text(preference),
                              selected: _selectedPreference == preference,
                              onSelected: (selected) {
                                modalSetState(() {
                                  _selectedPreference =
                                      selected ? preference : 'All';
                                });
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              selectedColor: appTheme.of(context).success,
                              backgroundColor: Colors.grey[200],
                              labelStyle: TextStyle(
                                color: _selectedPreference == preference
                                    ? Colors.white
                                    : appTheme.of(context).secondaryText,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Species Filter
                        Text(
                          'Filter by Species',
                          style: appTheme.of(context).headlineSmall.override(
                                fontFamily: 'Inter Tight',
                                color: appTheme.of(context).success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: speciesList.map((species) {
                                  return ChoiceChip(
                                    label: Text(species),
                                    selected: _selectedSpecies == species,
                                    onSelected: (selected) {
                                      modalSetState(() {
                                        _selectedSpecies =
                                            selected ? species : 'All';
                                      });
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    },
                                    selectedColor: appTheme.of(context).success,
                                    backgroundColor: Colors.grey[200],
                                    labelStyle: TextStyle(
                                      color: _selectedSpecies == species
                                          ? Colors.white
                                          : appTheme.of(context).secondaryText,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (_selectedCategory == 'Veterinarians') ...[
                        // Specialization Filter
                        Text(
                          'Filter by Specialization',
                          style: appTheme.of(context).headlineSmall.override(
                                fontFamily: 'Inter Tight',
                                color: appTheme.of(context).success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: specializationsList
                                    .map((specialization) {
                                  return ChoiceChip(
                                    label: Text(specialization),
                                    selected:
                                        _selectedSpecialization == specialization,
                                    onSelected: (selected) {
                                      modalSetState(() {
                                        _selectedSpecialization =
                                            selected ? specialization : 'All';
                                      });
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    },
                                    selectedColor: appTheme.of(context).success,
                                    backgroundColor: Colors.grey[200],
                                    labelStyle: TextStyle(
                                      color: _selectedSpecialization ==
                                              specialization
                                          ? Colors.white
                                          : appTheme.of(context).secondaryText,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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


  Widget _buildSearchField(Size size) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: size.height * 0.02),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04, vertical: size.height * 0.005),
              child: TextFormField(
                controller: _model.textController,
                decoration: InputDecoration(
                  hintText: 'Search pets or vets...',
                  hintStyle: appTheme.of(context).bodyLarge.override(
                        fontFamily: 'Inter',
                        letterSpacing: 0.0,
                      ),
                  border: InputBorder.none,
                ),
                style: appTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      letterSpacing: 0.0,
                    ),
                onChanged: (value) {
                  if (mounted) {
                    setState(
                        () {}); // Update the list dynamically as the user types
                  }
                },
              ),
            ),
          ),
          // Filter Icon Button
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 24),
            onPressed: () => showFilterModal(context), // Opens the filter modal
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return appChoiceChips(
      controller: _model.choiceChipsValueController ??=
          FormFieldController<List<String>>(['Pets']),
      chipSpacing: 8.0,
      multiselect: false,
      options: [
        ChipData('Pets', Icons.pets),
        ChipData('Veterinarians', Icons.medical_services),
      ],
      onChanged: (val) {
        if (mounted) {
          setState(() {
            _selectedCategory = val?.firstOrNull ?? 'Pets';
          });
        }
      },
      selectedChipStyle: ChipStyle(
        backgroundColor: appTheme.of(context).success,
        textStyle: appTheme.of(context).bodyMedium.override(
              fontFamily: 'Inter',
              color: Colors.white,
              letterSpacing: 0.0,
            ),
      ),
      unselectedChipStyle: ChipStyle(
        backgroundColor: const Color(0xFFF5F5F5),
        textStyle: appTheme.of(context).bodySmall.override(
              fontFamily: 'Inter',
              color: appTheme.of(context).secondaryText,
              letterSpacing: 0.0,
            ),
      ),
    );
  }
}
