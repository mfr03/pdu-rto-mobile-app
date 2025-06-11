// lib/features/profile/screens/user_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/features/authentication/screens/login/login_screen.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/features/profiles/screen/change_password_screen.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';
// import 'package:pdu_mobile_rto_app/features/profile/screens/change_password_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final AuthService _authService = GetIt.I<AuthService>();
  String? _email;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await _authService.getEmail();
    final name = await _authService.getUserName(); // Use the new method
    if (mounted) {
      setState(() {
        _email = email;
        _displayName = name; // Store the fetched/cached name
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
      ),
      child: ListTile(
        leading: Icon(icon, color: CColors.primaryColor),
        title: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: CColors.tertiaryColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background for the overall screen
      body: SafeArea( // Ensures content is not obscured by status bar
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CSizes.standardBorderRadiusSize * 1.5), // Approx 24.0, increased top padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // If you still want the PDU logo from the design at the top left (but not in an app bar):
              // Align(
              //   alignment: Alignment.topLeft,
              //   child: Container(
              //     margin: const EdgeInsets.only(bottom: 20),
              //     padding: const EdgeInsets.all(6),
              //     decoration: const BoxDecoration(
              //       color: CColors.primaryColor, // Or white if the logo needs a colored background
              //       shape: BoxShape.circle,
              //     ),
              //     child: const Icon(
              //       Icons.shield_outlined, // Placeholder for PDU star/logo
              //       color: Colors.white, // Or CColors.primaryColor
              //       size: 24,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 20), // Added some space at the top
              // Large Profile Icon
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CColors.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: CColors.primaryColor,
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // User Name
              Text(
                _displayName ?? 'Loading...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: CColors.tertiaryColor,
                ),
              ),
              const SizedBox(height: 5),

              // User Email
              Text(
                _email ?? 'Loading email...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              // Settings Buttons
              _buildSettingsButton(
                icon: Icons.lock_outline,
                text: 'Change Password',
                onPressed: _navigateToChangePassword,
              ),
              _buildSettingsButton(
                icon: Icons.logout,
                text: 'Logout',
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}