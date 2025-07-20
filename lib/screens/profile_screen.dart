import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  String? _imagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final database = Provider.of<DatabaseService>(context, listen: false);
    try {
      final profile = await database.getProfile();
      if (mounted) {
        setState(() {
          _nameController.text = profile['name'] ?? 'User';
          _imagePath = profile['imagePath'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nameController.text = 'User';
          _imagePath = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imagePath != null ? FileImage(File(_imagePath!)) : null,
                child: _imagePath == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<DatabaseService>(
                  context,
                  listen: false,
                ).updateProfile({
                  'name': _nameController.text,
                  'imagePath': _imagePath,
                });
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
