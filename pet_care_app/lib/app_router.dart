import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:pet_care_app/firebase/pet_class.dart';
import 'package:pet_care_app/main_screeen_manager.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/login_signup_screens/choose_role.dart';
import 'package:pet_care_app/screens/login_signup_screens/profile_info_screens/pet_owner_info.dart';
import 'package:pet_care_app/screens/login_signup_screens/profile_info_screens/vet_profile_info.dart';
import 'package:pet_care_app/screens/pet/add_pet/add_pet.dart';
import 'package:pet_care_app/screens/pets_and_vets_lists/vets_and_pets_lists_widget.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'common/app_theme.dart';
import 'providers/app_state_notifier.dart';
import 'screens/login_signup_screens/login_screens/login_screen.dart';
import 'screens/login_signup_screens/signup_screens/signup_screen.dart';
import 'screens/pet/pet_profile/pet_profile_widget.dart';
import 'screens/vet/vet_profile.dart';
import 'screens/pet_owner/pet_owner_profile_widget.dart';

class AppRouter {
  static GoRouter createRouter(AppStateNotifier appStateNotifier) {
    Logger logger = Logger();
    return GoRouter(
      initialLocation: '/login',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      redirect: (context, state) async {
        if (appStateNotifier.showSplashImage) {
          return '/splash';
        }
        final isLoggedIn = appStateNotifier.isLoggedIn;

        // If not logged in, redirect to login, except on login or signup pages
        if (!isLoggedIn &&
            state.uri.toString() != '/login' &&
            state.uri.toString() != '/signup' &&
            state.uri.toString() != '/choose-role' &&
            state.uri.toString() != '/vet-profile-info' &&
            state.uri.toString() != '/pet-owner-profile-info') {
          return '/login';
        }

        // If logged in, ensure users are not stuck on login or splash pages
        if (isLoggedIn &&
            (state.uri.toString() == '/login' ||
                state.uri.toString() == '/splash')) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.vet != null || authProvider.petOwner != null) {
            return '/main-screen';
          }
        }
        if(state.uri.toString() == '/splash'){
          logger.d('Redirecting to login from splash');
          return '/login';
        }

        return null; // No redirect
      },
      routes: [
        GoRoute(
          path: '/main-screen',
          builder: (context, state) => MainScreenManager(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreenWidget(),
        ),
        GoRoute(
          path: '/splash',
          builder: (context, state) => SplashScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);

            if (authProvider.vet != null) {
              logger.d('Logging into vet profile');
              return VetProfileWidget();
            } else if (authProvider.petOwner != null) {
              logger.d('Logging into pet owner profile');
              return PetOwnerPetListWidget();
            } else {
              return VetsandpetslistsWidget();
            }
          },
        ),
        GoRoute(
          path: '/pet-profile',
          builder: (context, state) {
            // Retrieve the Pet object from state.extra
            final Pet pet = state.extra as Pet;

            // Pass the Pet object to the PetProfileWidget
            return PetProfileWidget(
              pet: pet,
            );
          },
        ),
        GoRoute(
          path: '/vets-and-pets-lists',
          builder: (context, state) => VetsandpetslistsWidget(),
        ),
        GoRoute(
          path: '/choose-role',
          builder: (context, state) => ChooseRoleWidget(),
        ),
        GoRoute(
          path: '/vet-profile-info',
          builder: (context, state) {
            // Cast state.extra as Map<String, dynamic>
            final extraData = state.extra as Map<String, dynamic>?;

            // Safely retrieve email and password
            final email = extraData?['email'] as String? ?? '';
            final password = extraData?['password'] as String? ?? '';
            final isGoogleSignIn = extraData?['isGoogleSignIn'] as bool? ?? false;

            return VetSignUpInfoWidget(
              email: email,
              password: password,
              isGoogleSignIn: isGoogleSignIn,
            );
          },
        ),
        GoRoute(
          path: '/add-pet',
          builder: (context, state) => AddPetWidget(),
        ),
        GoRoute(
          path: '/pet-owner-profile-info',
          builder: (context, state) {
            // Cast state.extra as Map<String, dynamic>
            final extraData = state.extra as Map<String, dynamic>?;

            // Safely retrieve email and password
            final email = extraData?['email'] as String? ?? '';
            final password = extraData?['password'] as String? ?? '';
            final isGoogleSignIn = extraData?['isGoogleSignIn'] as bool? ?? false;

            return PetOwnerSignUpInfoWidget(
              email: email,
              password: password,
              isGoogleSignIn: isGoogleSignIn,
            );
          },
        ),
      ],
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/pet_paw.json', // Replace with actual animation
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text(
              "Welcome to PetCare",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: appTheme.of(context).success,
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
