import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:pet_care_app/app_router.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../../common/app_theme.dart';
import '../../../common/app_utils.dart';
import '../../../common/custom_widgets.dart';
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
//import 'package:provider/provider.dart';
import 'login_screen_model.dart';
export 'login_screen_model.dart';

class LoginScreenWidget extends StatefulWidget {
  const LoginScreenWidget({super.key});

  @override
  State<LoginScreenWidget> createState() => _LoginScreenWidgetState();
}

class _LoginScreenWidgetState extends State<LoginScreenWidget> {
  late LoginScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginScreenModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
  }

  Future<void> _signIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_model.textController1.text.isEmpty &&
        _model.textController2.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your email address and password.',
            textAlign: TextAlign.center,
            style: appTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
          ),
          backgroundColor: appTheme.of(context).error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      );
      return;
    } else if (_model.textController1.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your email address.',
            textAlign: TextAlign.center,
            style: appTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
          ),
          backgroundColor: appTheme.of(context).error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      );
      return;
    } else if (_model.textController2.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your password.',
            textAlign: TextAlign.center,
            style: appTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
          ),
          backgroundColor: appTheme.of(context).error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      );
      return;
    }
    try {
      await authProvider.signIn(
        _model.textController1!.text,
        _model.textController2!.text,
      );
      // Handle successful login
      logger.d('Successfully signed in: ${authProvider.user}');
    } catch (e) {
      // Handle login error
      String errorMessage;
      if (e.toString().contains('credential is incorrect')) {
        errorMessage =
            'Invalid email or password. Please try again, sign up, or use Google to sign in.';
      } else if (e.toString().contains('user-not-found')) {
        errorMessage =
            'Email not found. Please sign up or use Google to sign in.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later.';
      } else {
        errorMessage = 'Failed to sign in. Please try again.';
        print(e);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: appTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
          ),
          backgroundColor: appTheme.of(context).error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      );
      return;
    }

    context.go('/main-screen');
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

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
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.blue],
                    stops: [0.0, 1.0],
                    begin: AlignmentDirectional(0.0, -1.0),
                    end: AlignmentDirectional(0, 1.0),
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: Color(0x66000000),
                ),
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(8.0, 24.0, 8.0, 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                        child: _buildLogo(),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        child: _buildWelcomeText(),
                      ),
                      Material(
                        color: Colors.transparent,
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 24.0, 24.0, 24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: Text(
                                    'Welcome Back',
                                    style: appTheme
                                        .of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily: 'Inter Tight',
                                          color: appTheme.of(context).success,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: TextFormField(
                                    controller: _model.textController1,
                                    focusNode: _model.textFieldFocusNode1,
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: appTheme
                                          .of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                      hintStyle: appTheme
                                          .of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFFE0E0E0),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF5F5F5),
                                      suffixIcon: Icon(
                                        Icons.email,
                                      ),
                                    ),
                                    style:
                                        appTheme.of(context).bodyLarge.override(
                                              fontFamily: 'Inter',
                                              letterSpacing: 0.0,
                                            ),
                                    minLines: 1,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _model.textController1Validator
                                        .asValidator(context),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: TextFormField(
                                    controller: _model.textController2,
                                    focusNode: _model.textFieldFocusNode2,
                                    autofocus: false,
                                    obscureText: !_model.passwordVisibility,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: appTheme
                                          .of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                      hintStyle: appTheme
                                          .of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFFE0E0E0),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF5F5F5),
                                      suffixIcon: InkWell(
                                        onTap: () => setState(
                                          () => _model.passwordVisibility =
                                              !_model.passwordVisibility,
                                        ),
                                        focusNode:
                                            FocusNode(skipTraversal: true),
                                        child: Icon(
                                          _model.passwordVisibility
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    style:
                                        appTheme.of(context).bodyLarge.override(
                                              fontFamily: 'Inter',
                                              letterSpacing: 0.0,
                                            ),
                                    minLines: 1,
                                    validator: _model.textController2Validator
                                        .asValidator(context),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: ButtonWidget(
                                    onPressed: () async {
                                      await _signIn();
                                      print('Button pressed ...');
                                    },
                                    text: 'Sign In',
                                    options: ButtonOptions(
                                      width: MediaQuery.sizeOf(context).width,
                                      height: 50.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 0.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color: appTheme.of(context).success,
                                      textStyle: appTheme
                                          .of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'Inter Tight',
                                            color: Colors.white,
                                            letterSpacing: 0.0,
                                          ),
                                      elevation: 2.0,
                                      borderRadius: BorderRadius.circular(25.0),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Or Sign In with google account',
                                        style: appTheme
                                            .of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Inter',
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                      Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  8.0, 0.0, 8.0, 0.0),
                                          child: IconButton(
                                            onPressed: () async {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder:
                                                    (BuildContext context) {
                                                  return Center(
                                                    child: SplashScreen(),
                                                  );
                                                },
                                              );
                                              try {
                                                final authProvider =
                                                    Provider.of<AuthProvider>(
                                                        context,
                                                        listen: false);
                                                final isFirstTime =
                                                    await authProvider
                                                        .signInWithGoogle();

                                                Navigator.of(context)
                                                    .pop(); // Close the dialog

                                                if (isFirstTime) {
                                                  context.push('/choose-role');
                                                } else {
                                                  if (authProvider.vet !=
                                                          null ||
                                                      authProvider.petOwner !=
                                                          null) {
                                                    context
                                                        .push('/main-screen');
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Your previous signup was incomplete. Please restart the process to complete your registration.',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: appTheme
                                                              .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'Inter',
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                        backgroundColor:
                                                            appTheme
                                                                .of(context)
                                                                .error,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              } catch (e) {
                                                Navigator.of(context)
                                                    .pop(); // Close the dialog
                                                print(
                                                    'Error during Google Sign-In: $e');
                                              }
                                            },

                                            icon: Image.asset(
                                              'assets/icons/GoogleIcon.png',
                                              scale: 35,
                                            ), // ImageIcon(AssetImage('assets/icons/GoogleIcon.png')),
                                          )),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Don\'t have an account?',
                                        style: appTheme
                                            .of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Inter',
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          // Navigate to the Sign Up screen
                                          context.go('/signup');
                                          // Use a logging framework instead of print
                                          debugPrint('Sign Up pressed ...');
                                        },
                                        child: Text(
                                          'Sign Up',
                                          style: appTheme
                                              .of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Inter',
                                                color: appTheme
                                                    .of(context)
                                                    .success,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ].divide(SizedBox(width: 8.0)),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Handle the tap event, e.g., navigate to terms and privacy policy page
                                      showAboutDialog(context: context);
                                    },
                                    child: Text(
                                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                                      textAlign: TextAlign.center,
                                      style: appTheme
                                          .of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily: 'Inter',
                                            color: appTheme.of(context).success,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(height: 18.0)),
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 24.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/AppIcon.png',
      width: MediaQuery.of(context).size.width * 0.25,
      height: MediaQuery.of(context).size.width * 0.25,
      fit: BoxFit.fill,
    );
  }
  
  Widget _buildWelcomeText() {
    return Column(
      children: [
        Center(
          child: Text(
            'Welcome to PetCare',
            style: appTheme.of(context).displaySmall.override(
                  fontFamily: 'Inter Tight',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Center(
          child: Text(
            'Your trusted companion in pet healthcare',
            style: appTheme.of(context).bodyLarge.override(
                  fontFamily: 'Inter',
                  color: const Color(0xFFE0E0E0),
                ),
          ),
        ),
      ],
    );
  }

}
