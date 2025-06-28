import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/fcm_service.dart';
import 'package:pdu_mobile_rto_app/features/admin/screen/admin_screen.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/features/wells_selections/wells_active.dart';
import 'package:pdu_mobile_rto_app/generated/l10n.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';
import 'package:pdu_mobile_rto_app/utils/theme/text_theme.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final AuthService _authService = Get.find<AuthService>();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userData = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted) { // Check if the widget is still in the tree
          if (userData != null) {

            final String role = userData['role'] ?? 'USER';

            final FcmService fcmService = Get.find<FcmService>();
            await fcmService.registerDeviceWithPduServer();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).loginSuccessful)),
            );

            if (role.toUpperCase() == 'ADMIN') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WellsActiveScreen()),
              );
            }
          }
          // No 'else' needed here as login service throws an exception on failure
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login Failed: ${e.toString().replaceFirst("Exception: ", "")}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [

          Container(color: CColors.tertiaryColor.withOpacity(0.85)),

          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400), // Max width for the login card
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(CSizes.standardBorderRadiusSize * 1.5), // Approx 24.0
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[

                          Image.asset(
                            'assets/images/logo.png',
                            height: 60, // Adjust as needed
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback logo like in the design image
                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                          )
                                        ]
                                    ),
                                    child: const Text(
                                      'pdu',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: CColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  // Optional: Sub-text if it's part of your logo
                                  // const Text(
                                  //  "Professional Drilling Utility",
                                  //  style: TextStyle(fontSize: 10, color: Colors.grey),
                                  // ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Welcome back!',
                            style: CTextTheme.lightTextTheme.headlineMedium?.copyWith(
                              color: CColors.tertiaryColor, // Use a dark color for text on light card
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please enter your details',
                            style: CTextTheme.lightTextTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          // Email TextFormField (labeled as Username in design, but using Email for backend)
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email', // Changed from Username to Email
                              // prefixIcon: Icon(Icons.person_outline), // Or Icons.email_outlined
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password TextFormField
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              // prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              // Add more password validation if needed (e.g., length)
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CColors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: CTextTheme.lightTextTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                                  : const Text('Login'),
                            ),
                          ),
                          // Optional: Add "Forgot Password?" or "Sign Up" links if needed
                          // const SizedBox(height: 20),
                          // TextButton(
                          //   onPressed: () {
                          //     // TODO: Navigate to forgot password screen
                          //   },
                          //   child: Text(
                          //     'Forgot Password?',
                          //     style: TextStyle(color: CColors.primaryColor),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}