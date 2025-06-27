// lib/features/admin/widgets/add_user_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/features/admin/models/company.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/generated/l10n.dart';
import 'package:pdu_mobile_rto_app/main.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddUserDialog extends StatefulWidget {
  final VoidCallback onUserAdded; // Callback to refresh user list

  const AddUserDialog({super.key, required this.onUserAdded});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = Get.find<AuthService>();

  List<Company> _companies = [];
  Company? _selectedCompany;
  String? _selectedRole = 'USER'; // Default role
  final List<String> _roles = ['USER', 'ADMIN'];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoadingCompanies = true;
  bool _isAddingUser = false;
  String? _companyFetchError;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() {
      _isLoadingCompanies = true;
      _companyFetchError = null;
    });
    try {
      final companies = await _authService.getCompanies();
      if (mounted) {
        setState(() {
          _companies = companies;
          _isLoadingCompanies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _companyFetchError = e.toString().replaceFirst("Exception: ", "");
          _isLoadingCompanies = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {

    if (_formKey.currentState!.validate() && _selectedCompany != null) {
      setState(() => _isAddingUser = true);
      try {
        bool success = await _authService.addEmployee(
          companyId: _selectedCompany!.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole!,
          password: _passwordController.text,
        );

        if (mounted) {
          if (success) {

            Fluttertoast.showToast(
                msg: S.of(context).userAddedSuccessfully,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16.0
            );

            widget.onUserAdded(); // Call callback to refresh list
            Navigator.of(context).pop(); // Close dialog
          }
          // Error case is handled by catch block
        }
      } catch (e) {
        if (mounted) {

          Fluttertoast.showToast(
              msg: S.of(context).failedToAddUserEtostringreplacefirstexception,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0
          );

        }
      } finally {
        if (mounted) {
          setState(() => _isAddingUser = false);
        }
      }
    } else if (_selectedCompany == null && !_isLoadingCompanies) {

      Fluttertoast.showToast(
          msg: S.of(context).pleaseSelectACompany,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.orangeAccent,
          textColor: Colors.white,
          fontSize: 16.0
      );

    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).addNewUser, style: TextStyle(color: CColors.primaryColor)),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6, // Adjust as needed
          minWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: _isLoadingCompanies
            ? const Center(child: CircularProgressIndicator(color: CColors.primaryColor))
            : _companyFetchError != null
            ? Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(S.of(context).errorFetchingCompaniesCompanyfetcherror, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _fetchCompanies, child: Text(S.of(context).retry))
          ],
        )
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<Company>(
                  decoration: InputDecoration(labelText: S.of(context).company, border: OutlineInputBorder()),
                  value: _selectedCompany,
                  hint: Text(S.of(context).selectCompany),
                  isExpanded: true,
                  items: _companies.map((Company company) {
                    return DropdownMenuItem<Company>(
                      value: company,
                      child: Text(company.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (Company? newValue) {
                    setState(() {
                      _selectedCompany = newValue;
                    });
                  },
                  validator: (value) => value == null ? S.of(context).companyIsRequired : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: S.of(context).name, border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return S.of(context).nameIsRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: S.of(context).email, border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return S.of(context).emailIsRequired;
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                      return S.of(context).enterAValidEmailAddress;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: S.of(context).role, border: OutlineInputBorder()),
                  value: _selectedRole,
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  },
                  validator: (value) => value == null ? S.of(context).roleIsRequired : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: S.of(context).password, border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).passwordIsRequired;
                    }
                    if (value.length < 6) { // Example: minimum length
                      return S.of(context).passwordMustBeAtLeast6Characters;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(S.of(context).cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: CColors.primaryColor, foregroundColor: Colors.white),
          onPressed: _isAddingUser ? null : _submitForm,
          child: _isAddingUser
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(S.of(context).addUser),
        ),
      ],
    );
  }
}