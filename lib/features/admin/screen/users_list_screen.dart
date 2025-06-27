// lib/features/admin/screens/users_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/features/admin/models/app_user_model.dart';
import 'package:pdu_mobile_rto_app/features/admin/widgets/add_user_dialog.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/generated/l10n.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final AuthService _authService = Get.find<AuthService>();
  late Future<List<AppUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _authService.getAllUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _authService.getAllUsers();
    });
  }

  void _openAddUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddUserDialog(onUserAdded: () {
          _refreshUsers(); // Refresh the list after a user is added
        });
      },
    );
  }


  Widget _buildUserListItem(AppUser user) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: CSizes.standardBorderRadiusSize / 2, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: CColors.primaryColor.withOpacity(0.2),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(color: CColors.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 2),
            Text(S.of(context).roleUserrole, style: Theme.of(context).textTheme.bodySmall),
            // Text('Company ID: ${user.companyId}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () {
          // TODO: Implement navigation to a user detail screen or edit screen if needed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on ${user.name}')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).applicationUsers, style: TextStyle(color: Colors.white)),
        backgroundColor: CColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: S.of(context).refreshUsers,
            onPressed: _refreshUsers,
          ),
        ],
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CColors.primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      S.of(context).errorSnapshoterrortostringreplacefirstexception,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(S.of(context).retry, style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: CColors.primaryColor),
                      onPressed: _refreshUsers,
                    )
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(S.of(context).noUsersFound, style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text(S.of(context).refresh, style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: CColors.primaryColor),
                    onPressed: _refreshUsers,
                  )
                ],
              ),
            );
          }

          final users = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(CSizes.standardBorderRadiusSize / 2), // 8.0
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserListItem(users[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddUserDialog,
        backgroundColor: CColors.primaryColor,
        tooltip: S.of(context).addNewUser,
        child: const Icon(Icons.add, color: Colors.white),

      ),
    );
  }
}