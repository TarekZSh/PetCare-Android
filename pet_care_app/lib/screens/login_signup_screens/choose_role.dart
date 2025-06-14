import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:pet_care_app/common/icon_button_widget.dart';
import 'package:pet_care_app/firebase/pet_owner_class.dart';
import 'package:pet_care_app/firebase/vet_class.dart';
import '/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '/common/app_theme.dart';

class ChooseRoleWidget extends StatefulWidget {
  const ChooseRoleWidget({super.key});

  @override
  State<ChooseRoleWidget> createState() => _ChooseRoleWidgetState();
}

class _ChooseRoleWidgetState extends State<ChooseRoleWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      FocusScope.of(context).unfocus();
    },
    child: Scaffold(
      key: scaffoldKey,
      backgroundColor: appTheme.of(context).primaryBackground,
      body: Container(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: Stack(
          children: [
            // Background gradient
            Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.blue],
                  stops: [0, 1],
                  begin: AlignmentDirectional(0, -1),
                  end: AlignmentDirectional(0, 1),
                ),
              ),
            ),
            // Semi-transparent overlay
            Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              decoration: BoxDecoration(
                color: Color(0x66000000),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 16),

                    // Top-left IconButton now scrollable
                    Align(
                      alignment: Alignment.topLeft,
                      child: appIconButton(
                        borderRadius: 20.0,
                        buttonSize: MediaQuery.sizeOf(context).width * 0.1,
                        fillColor: Color(0x33FFFFFF),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: MediaQuery.sizeOf(context).width * 0.05,
                        ),
                        onPressed: () async {
                          Logger().i('Back button pressed');
                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);
                          bool? confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Delete Account'),
                                content: Text(
                                    'Are you sure you want to go back? You will need to sign in again.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      'Go back',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            try {
                              await authProvider.deleteAccount();
                              context
                                  .go('/login'); // Redirect to login after deletion
                            } catch (e) {
                              // Handle potential errors (e.g., requires-recent-login)
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Error'),
                                  content: Text(e.toString()),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.02),
                          Text(
                            'Choose Your Role',
                            style: appTheme.of(context).displaySmall.override(
                                  fontFamily: 'Inter Tight',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select how you\'d like to use PetCare',
                            style: appTheme.of(context).bodyLarge.override(
                                  fontFamily: 'Inter',
                                  color: Color(0xFFE0E0E0),
                                ),
                          ),
                          const SizedBox(height: 32),
                          _buildRoleCard(
                            context,
                            icon: Icons.pets,
                            title: 'Pet Owner',
                            description:
                                'Create profiles for your pets, schedule vet visits, and track their health journey.',
                            onTap: () async {
                              context.push(
                                '/pet-owner-profile-info',
                                extra: {
                                  'isGoogleSignIn': true,
                                },
                              );
                              print('Pet owner info going');
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildRoleCard(
                            context,
                            icon: Icons.medical_services,
                            title: 'Veterinarian',
                            description:
                                'Manage appointments, access patient records, and provide professional care.',
                            onTap: () async {
                              context.push(
                                '/vet-profile-info',
                                extra: {
                                  'isGoogleSignIn': true,
                                },
                              );
                              print('Vet info going');
                            },
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'You can\'t change your role later.',
                            textAlign: TextAlign.center,
                            style: appTheme.of(context).bodySmall.override(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                ),
                          ),
                        ],
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


  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(icon, color: appTheme.of(context).success, size: 40),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: appTheme.of(context).headlineSmall.override(
                        fontFamily: 'Inter Tight',
                        color: appTheme.of(context).success,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: appTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: appTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
