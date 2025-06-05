// lib/features/admin/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/features/admin/screen/users_list_screen.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/features/wells_selections/wells_active.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';
import 'package:pdu_mobile_rto_app/features/authentication/screens/login/login_screen.dart'; // For logout

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _authService = GetIt.I<AuthService>();
  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final email = await _authService.getEmail();
    if (mounted) {
      setState(() {
        _adminEmail = email;
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

  Widget _buildAdminOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: CColors.primaryColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CColors.tertiaryColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light overall background
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: CColors.primaryColor,
        elevation: 2.0,
        automaticallyImplyLeading: false, // Remove back button if it's a main screen
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CSizes.standardBorderRadiusSize),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Welcome, Admin!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: CColors.tertiaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_adminEmail != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                child: Text(
                  _adminEmail!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            _buildAdminOptionCard(
              icon: Icons.people_alt_outlined,
              title: 'Manage Users',
              subtitle: 'View and manage application users',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersListScreen()),
                );
              },
            ),
            _buildAdminOptionCard(
              icon: Icons.select_all_outlined, // Or a more specific icon for wells
              title: 'Well Selections',
              subtitle: 'Access and view well data',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WellsActiveScreen()),
                );
              },
            ),
            // You can add more admin-specific options here if needed
          ],
        ),
      ),
    );
  }
}