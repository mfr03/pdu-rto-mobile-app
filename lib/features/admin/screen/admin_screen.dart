// lib/features/admin/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/features/admin/screen/users_list_screen.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/features/wells_selections/wells_active.dart';
import 'package:pdu_mobile_rto_app/generated/l10n.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';
import 'package:pdu_mobile_rto_app/features/authentication/screens/login/login_screen.dart'; // For logout


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _authService = Get.find<AuthService>();
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

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
      ),
      color: colorScheme.secondary,
      child: InkWell(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: colorScheme.onSecondary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: CColors.white),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Light overall background
      appBar: AppBar(
        title: Text(
          S.of(context).adminPanel,
          style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 2.0,
        automaticallyImplyLeading: false, // Remove back button if it's a main screen
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: S.of(context).logout,
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
              S.of(context).welcomeAdmin,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(140),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_adminEmail != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                child: Text(
                  _adminEmail!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(140),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            _buildAdminOptionCard(
              icon: Icons.people_alt_outlined,
              title: S.of(context).manageUsers,
              subtitle: S.of(context).viewAndManageApplicationUsers,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersListScreen()),
                );
              },
            ),
            _buildAdminOptionCard(
              icon: Icons.select_all_outlined, // Or a more specific icon for wells
              title: S.of(context).wellSelections,
              subtitle: S.of(context).accessAndViewWellData,
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