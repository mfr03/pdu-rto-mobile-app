// lib/features/profile/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = Get.find<AuthService>();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _oldPasswordObscured = true;
  bool _newPasswordObscured = true;
  bool _confirmPasswordObscured = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitChangePassword() async {
    setState(() {
      _errorMessage = null; // Clear previous errors
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      final oldPassword = _oldPasswordController.text;
      final newPassword = _newPasswordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (newPassword != confirmPassword) {
        setState(() {
          _errorMessage = 'New passwords do not match.';
          _isLoading = false;
        });
        return;
      }

      try {
        String? employeeId = await _authService.getEmployeeId();
        if (employeeId == null) {
          throw Exception("User employee ID not found. Please re-login.");
        }

        bool success = await _authService.changePassword(
          employeeId: employeeId,
          oldPassword: oldPassword,
          newPassword: newPassword,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password changed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(); // Go back to UserSettingsScreen
          }
          // If success is false but no exception, AuthService.changePassword would have thrown for API errors
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().replaceFirst("Exception: ", "");
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback onVisibilityToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        // Based on the design, a simple border or underline might be better than a full card
        // For consistency with login, using OutlineInputBorder
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
          borderSide: const BorderSide(color: CColors.primaryColor),
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12.0, right: 8.0),
          child: Icon(Icons.lock_outline, color: Colors.grey),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: onVisibilityToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (label.toLowerCase().contains("new") && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Change Password'),
        // Inherits style from MaterialApp's appBarTheme (CColors.primaryColor bg, white text)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CSizes.standardBorderRadiusSize * 1.5), // Approx 24.0
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              // The design shows password fields inside a card.
              Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildPasswordTextField(
                        controller: _oldPasswordController,
                        label: 'Enter old password',
                        isObscured: _oldPasswordObscured,
                        onVisibilityToggle: () => setState(() => _oldPasswordObscured = !_oldPasswordObscured),
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordTextField(
                        controller: _newPasswordController,
                        label: 'Enter new password',
                        isObscured: _newPasswordObscured,
                        onVisibilityToggle: () => setState(() => _newPasswordObscured = !_newPasswordObscured),
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordTextField(
                        controller: _confirmPasswordController,
                        label: 'Re-type new password',
                        isObscured: _confirmPasswordObscured,
                        onVisibilityToggle: () => setState(() => _confirmPasswordObscured = !_confirmPasswordObscured),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
                        ),
                      ),
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isLoading
                          ? Container() // No icon when loading
                          : const Icon(Icons.save_outlined, color: Colors.white),
                      label: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Save', style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitChangePassword,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}