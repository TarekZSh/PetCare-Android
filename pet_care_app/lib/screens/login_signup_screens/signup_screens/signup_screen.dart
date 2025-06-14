import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/common/choice_chips_widget.dart';
import '/common/app_theme.dart';
import '/common/app_utils.dart';
import '/common/custom_widgets.dart';
import '/common/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'signup_screen_model.dart';
export 'signup_screen_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late SignupScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignupScreenModel());
    _initializeControllers();
  }

  void _initializeControllers() {
    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();
    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();
  }

  Future<void> _signUp() async {
    if (_areFieldsEmpty()) {
      _showSnackBar('Please fill in all fields', appTheme.of(context).error);
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
        .hasMatch(_model.textController2!.text)) {
      _showSnackBar(
          'Please enter a valid email address', appTheme.of(context).error);
      return;
    }
    if (_model.textController3.text != _model.textController4.text) {
      _showSnackBar('Passwords do not match', appTheme.of(context).error);
      return;
    }
    if (_model.textController3.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters long', appTheme.of(context).error);
      return;
    }

    try {
      if (_model.choiceChipsValue == 'Pet Owner') {
        Logger().i('Signing up as a Pet Owner');
        context.push(
          '/pet-owner-profile-info',
          extra: {
            'email':
                _model.textController2!.text, // Replace with actual email value
            'password': _model
                .textController3!.text, // Replace with actual password value
          },
        );
      } else {
        Logger().i('Signing up as a Veterinarian');
        context.push(
          '/vet-profile-info',
          extra: {
            'email':
                _model.textController2!.text, // Replace with actual email value
            'password': _model
                .textController3!.text, // Replace with actual password value
          },
        );
      }
    } catch (e) {
      _handleSignUpError(e);
    }
  }

  bool _areFieldsEmpty() {
    return _model.textController2!.text.isEmpty &&
        _model.textController3!.text.isEmpty &&
        _model.textController4!.text.isEmpty;
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: appTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: Colors.white,
              ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(16.0),
      ),
    );
  }

  void _handleSignUpError(dynamic error) {
    String errorMessage;
    if (error.toString().contains('email-already-in-use')) {
      errorMessage =
          'Email already in use. Please use a different email or sign in.';
    } else if (error.toString().contains('weak-password')) {
      errorMessage = 'Password is too weak. Please use a stronger password.';
    } else if (error.toString().contains('invalid-email')) {
      errorMessage = 'Invalid email. Please enter a valid email address.';
    } else {
      errorMessage = 'Failed to sign up. Please try again.';
    }
    _showSnackBar(errorMessage, appTheme.of(context).error);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: appTheme.of(context).primaryBackground,
        body: Stack(
          children: [
            _buildGradientBackground(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Stack(
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
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          decoration: const BoxDecoration(
            color: Color(0x66000000), // Semi-transparent overlay
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(8, 24, 8, 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLogo(),
            const SizedBox(height: 16.0),
            _buildWelcomeText(),
            const SizedBox(height: 24.0),
            _buildFormContainer(),
          ],
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
        Text(
          'Welcome to PetCare',
          style: appTheme.of(context).displaySmall.override(
                fontFamily: 'Inter Tight',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          'Your trusted companion in pet healthcare',
          style: appTheme.of(context).bodyLarge.override(
                fontFamily: 'Inter',
                color: const Color(0xFFE0E0E0),
              ),
        ),
      ],
    );
  }

  Widget _buildFormContainer() {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0, 8, 0, 8),
      child: Material(
        color: Colors.transparent,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            children: [
              _buildFormTitle(),
              const SizedBox(height: 16.0),
              _buildChoiceChips(),
              const SizedBox(height: 16.0),
              _buildTextFields(),
              const SizedBox(height: 24.0),
              _buildSignUpButton(),
              const SizedBox(height: 16.0),
              _buildSignInText(),
              const SizedBox(height: 16.0),
              _buildTermsText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTitle() {
    return Text(
      'Create Account',
      style: appTheme.of(context).headlineSmall.override(
            fontFamily: 'Inter Tight',
            color: appTheme.of(context).success,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildChoiceChips() {
    return appChoiceChips(
      options: [ChipData('Pet Owner'), ChipData('Veterinarian')],
      onChanged: (val) =>
          safeSetState(() => _model.choiceChipsValue = val?.firstOrNull),
      selectedChipStyle: ChipStyle(
        backgroundColor: appTheme.of(context).success,
        textStyle: appTheme.of(context).bodyMedium.override(
              fontFamily: 'Inter',
              color: Colors.white,
            ),
        borderRadius: BorderRadius.circular(25.0),
      ),
      unselectedChipStyle: ChipStyle(
        backgroundColor: const Color(0xFFF5F5F5),
        textStyle: appTheme.of(context).bodySmall.override(
              fontFamily: 'Inter',
              color: appTheme.of(context).secondaryText,
            ),
        borderRadius: BorderRadius.circular(25.0),
      ),
      controller: _model.choiceChipsValueController ??=
          FormFieldController<List<String>>(['Pet Owner']),
      chipSpacing: 8.0,
      multiselect: false,
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        _buildTextField(
          'Email Address',
          _model.textController2,
          _model.textFieldFocusNode2,
          TextInputType.emailAddress,
        ),
        const SizedBox(height: 16.0),
        _buildPasswordField(
          'Password',
          _model.textController3,
          _model.textFieldFocusNode3,
          _model.passwordVisibility1,
          () => setState(
              () => _model.passwordVisibility1 = !_model.passwordVisibility1),
        ),
        const SizedBox(height: 16.0),
        _buildPasswordField(
          'Confirm Password',
          _model.textController4,
          _model.textFieldFocusNode4,
          _model.passwordVisibility2,
          () => setState(
              () => _model.passwordVisibility2 = !_model.passwordVisibility2),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController? controller,
      FocusNode? focusNode, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: _buildInputBorder(Color(0xFFE0E0E0)),
        focusedBorder: _buildInputBorder(Color(0xFFE0E0E0)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildPasswordField(String label, TextEditingController? controller,
      FocusNode? focusNode, bool visibility, VoidCallback toggleVisibility) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !visibility,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: toggleVisibility, // Call the toggle function directly
          icon: Icon(visibility ? Icons.visibility : Icons.visibility_off),
        ),
        enabledBorder: _buildInputBorder(Color(0xFFE0E0E0)),
        focusedBorder: _buildInputBorder(Color(0xFFE0E0E0)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
      ),
    );
  }

  InputBorder _buildInputBorder(Color color) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color, width: 1.0),
      borderRadius: BorderRadius.circular(8.0),
    );
  }

  Widget _buildSignUpButton() {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
      child: ButtonWidget(
        onPressed: _signUp,
        text: 'Sign Up',
        options: ButtonOptions(
          width: MediaQuery.sizeOf(context).width,
          height: 50,
          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
          iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
          color: appTheme.of(context).success,
          textStyle: appTheme.of(context).titleMedium.override(
                fontFamily: 'Inter Tight',
                color: Colors.white,
                letterSpacing: 0.0,
              ),
          elevation: 2,
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  Widget _buildSignInText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: appTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: appTheme.of(context).secondaryText,
              ),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text(
            'Sign In',
            style: appTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: appTheme.of(context).success,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ].divide(SizedBox(width: 8.0)),
    );
  }

  Widget _buildTermsText() {
    return GestureDetector(
      onTap: () {
        showAboutDialog(context: context);
      },
      child: Text(
        'By signing up, you agree to our Terms of Service and Privacy Policy',
        textAlign: TextAlign.center,
        style: appTheme.of(context).bodySmall.override(
              fontFamily: 'Inter',
              color: appTheme.of(context).success,
              //decoration: TextDecoration.underline,
            ),
      ),
    );
  }
}
