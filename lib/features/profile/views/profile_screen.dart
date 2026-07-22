/*
  profile_screen.dart
  User profile screen. Displays and allows editing of user profile
  information such as first name, last name and gender. Persists profile
  data via `DatabaseService` (Firestore) for the signed-in user.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitquest/core/theme/app_theme.dart';
import 'package:fitquest/features/auth/view_models/auth_viewmodel.dart';
import 'package:fitquest/core/services/databse_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _db = DatabaseService();
  String _firstName = '';
  String _lastName = '';
  String _gender = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final profile = await _db.getUserProfile();
    setState(() {
      _firstName = (profile['firstName'] as String?) ?? '';
      _lastName = (profile['lastName'] as String?) ?? '';
      _gender = (profile['gender'] as String?) ?? '';
      _loading = false;
    });
  }

  Future<void> _editProfileDialog() async {
    final f = TextEditingController(text: _firstName);
    final l = TextEditingController(text: _lastName);
    final g = TextEditingController(text: _gender);

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: f,
                decoration: const InputDecoration(labelText: 'First name')),
            TextField(
                controller: l,
                decoration: const InputDecoration(labelText: 'Last name')),
            TextField(
                controller: g,
                decoration: const InputDecoration(labelText: 'Gender')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _db.updateUserProfile({
                'firstName': f.text.trim(),
                'lastName': l.text.trim(),
                'gender': g.text.trim(),
              });
              setState(() {
                _firstName = f.text.trim();
                _lastName = l.text.trim();
                _gender = g.text.trim();
              });
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthViewModel>(context);
    final user = auth.user;
    final email = user?.email ?? 'Not logged in';
    final displayName = (_firstName.isNotEmpty || _lastName.isNotEmpty)
        ? '$_firstName ${_lastName}'.trim()
        : (user?.displayName ?? user?.email?.split('@').first ?? 'User');
    final joinDate = user?.metadata.creationTime ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                            ),
                            child: Center(
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _editProfileDialog,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoItem(
                            icon: Icons.person_outline,
                            label: 'Member Since',
                            value:
                                '${joinDate.day}/${joinDate.month}/${joinDate.year}',
                          ),
                          _buildInfoItem(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: email,
                          ),
                          _buildInfoItem(
                            icon: Icons.badge_outlined,
                            label: 'Name',
                            value: displayName,
                          ),
                          _buildInfoItem(
                            icon: Icons.transgender,
                            label: 'Gender',
                            value: _gender.isNotEmpty ? _gender : 'Not set',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => auth.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
