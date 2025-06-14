import 'package:flutter/material.dart';
import 'package:pet_care_app/common/app_theme.dart';
import 'package:pet_care_app/common/base_model.dart';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/pets_and_vets_lists/detailed_view.dart';
import 'package:pet_care_app/screens/vet/vet_patient_list/vet_patient_list_model.dart';
import 'package:provider/provider.dart';

class VetPatientListWidget extends StatefulWidget {
  const VetPatientListWidget({super.key});

  @override
  State<VetPatientListWidget> createState() => _VetPatientListWidgetState();
}

class _VetPatientListWidgetState extends State<VetPatientListWidget> {
  late VetPatientListModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VetPatientListModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Widget _buildPetCard(Pet pet, BuildContext context, {int index = 0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define colors based on pet attributes
    final Color cardColor = index % 2 == 0
        ? const Color(0xFFE8F5E9) // Soft green for even cards
        : const Color(0xFFE3F2FD); // Soft blue for odd cards

    return GestureDetector(
      onTap: () async {
        await PetDetailModal.show(
          context,
          pet,
          index,
          onUpdate: () {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            authProvider.vet?.patients.remove(pet); // Remove from the provider
          },
        );
      },
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor, // Alternate background color
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Row(
              children: [
                // Pet image
                CircleAvatar(
                  radius: screenWidth * 0.1,
                  backgroundImage: pet.imageUrl != null
                      ? NetworkImage(pet.imageUrl!)
                      : const AssetImage('assets/images/PetProfilePicture.png')
                          as ImageProvider,
                ),
                SizedBox(width: screenWidth * 0.04),
                // Pet details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: appTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              color: appTheme.of(context).primaryText,
                            ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        pet.breed,
                        style: appTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: appTheme.of(context).secondaryText,
                            ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        '${pet.age.toStringAsFixed(1)} years old',
                        style: appTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: appTheme.of(context).secondaryText,
                            ),
                      ),
                    ],
                  ),
                ),
                // Icon for additional actions
                Icon(
                  Icons.arrow_forward_ios,
                  color: appTheme.of(context).secondaryText,
                  size: screenWidth * 0.05,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPatientList(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = screenWidth * 0.1;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final patients = authProvider.vet?.patients ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            patients.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pets,
                        color: Colors.grey,
                        size: iconSize,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Center(
                        child: Text(
                          'No patients yet',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      return _buildPetCard(patients[index], context, index: index);
                    },
                  ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Container(
          width: screenWidth,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32.0),
              topRight: Radius.circular(32.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 0.0, 8, 0.0),
            child: buildPatientList(context),
          ),
        ),
      ],
    );
  }
}
