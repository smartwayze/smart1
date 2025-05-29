import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class TailorProfilePage extends StatefulWidget {
  @override
  _TailorProfilePageState createState() => _TailorProfilePageState();
}

class _TailorProfilePageState extends State<TailorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _bioController = TextEditingController();
  List<String> _selectedServices = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  File? _localProfileImage;
  String? _profileImageUrl;
  bool _hasLocalImage = false;
  List<File> _designImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _serviceOptions = [
    'Stitching',
    'Designing',
    'Alterations',
    'Embroidery',
    'Bridal',
    'Men\'s Wear',
    'Kids Wear'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadLocalImages();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('tailors')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _shopNameController.text = data['shopName'] ?? '';
        _specializationController.text = data['specialization'] ?? '';
        _experienceController.text = data['experience']?.toString() ?? '';
        _priceRangeController.text = data['priceRange'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _selectedServices = List<String>.from(data['services'] ?? []);
        _hasLocalImage = data['hasLocalImage'] ?? false;
        _profileImageUrl = data['profileImageUrl'];

        if (_hasLocalImage) {
          await _loadLocalProfileImage(data['profileImagePath']);
        }

        setState(() => _isEditMode = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLocalProfileImage(String? path) async {
    if (path == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localPath = prefs.getString('profile_image_path') ?? path;

      if (await File(localPath).exists()) {
        setState(() {
          _localProfileImage = File(localPath);
        });
      } else {
        await FirebaseFirestore.instance
            .collection('tailors')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          'hasLocalImage': false,
          'profileImagePath': null,
        });
      }
    } catch (e) {
      print('Error loading local profile image: $e');
    }
  }

  Future<void> _loadLocalImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final designCount = prefs.getInt('design_images_count') ?? 0;
      List<File> designs = [];

      for (int i = 0; i < designCount; i++) {
        final path = prefs.getString('design_image_$i');
        if (path != null && await File(path).exists()) {
          designs.add(File(path));
        }
      }

      setState(() {
        _designImages = designs;
      });
    } catch (e) {
      print('Error loading local images: $e');
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final permission = await Permission.photos.request();
      if (!permission.isGranted) return;

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null || !mounted) return;

      if (isProfile) {
        await _processProfileImage(File(pickedFile.path));
      } else {
        await _processDesignImage(File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processProfileImage(File image) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Save locally
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${user.uid}.jpg';
    final newPath = '${directory.path}/$fileName';
    final savedImage = await image.copy(newPath);

    // 2. Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', newPath);

    // 3. Update Firestore
    await FirebaseFirestore.instance
        .collection('tailors')
        .doc(user.uid)
        .update({
      'profileImagePath': newPath,
      'hasLocalImage': true,
      'profileImageUrl': null,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    setState(() {
      _localProfileImage = savedImage;
      _hasLocalImage = true;
      _profileImageUrl = null;
    });
  }

  Future<void> _processDesignImage(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'design_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${directory.path}/$fileName';
    final savedImage = await image.copy(newPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('design_image_${_designImages.length}', newPath);
    await prefs.setInt('design_images_count', _designImages.length + 1);

    setState(() => _designImages.add(savedImage));
  }

  Future<void> _uploadToFirebaseStorage() async {
    if (_localProfileImage == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}.jpg');

      await ref.putFile(_localProfileImage!);
      final downloadUrl = await ref.getDownloadURL();

      // 2. Update Firestore
      await FirebaseFirestore.instance
          .collection('tailors')
          .doc(user.uid)
          .update({
        'profileImageUrl': downloadUrl,
        'hasLocalImage': false,
        'profileImagePath': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // 3. Clean up local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_path');
      if (await _localProfileImage!.exists()) {
        await _localProfileImage!.delete();
      }

      setState(() {
        _profileImageUrl = downloadUrl;
        _hasLocalImage = false;
        _localProfileImage = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeDesignImage(int index) async {
    try {
      // Delete the file
      await _designImages[index].delete();

      // Update the list
      setState(() => _designImages.removeAt(index));

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('design_image_$index');

      // Reorganize remaining images
      for (int i = index; i < _designImages.length; i++) {
        final path = prefs.getString('design_image_${i+1}');
        if (path != null) {
          await prefs.setString('design_image_$i', path);
          await prefs.remove('design_image_${i+1}');
        }
      }

      await prefs.setInt('design_images_count', _designImages.length);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to save profile')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileData = {
        'shopName': _shopNameController.text,
        'specialization': _specializationController.text,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'priceRange': _priceRangeController.text,
        'bio': _bioController.text,
        'services': _selectedServices,
        'hasLocalImage': _hasLocalImage,
        'profileImagePath': _localProfileImage?.path,
        'profileImageUrl': _profileImageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': user.uid,
      };

      await FirebaseFirestore.instance
          .collection('tailors')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isProfileComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _isEditMode = true);
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: _hasLocalImage && _localProfileImage != null
                  ? FileImage(_localProfileImage!)
                  : _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: _localProfileImage == null && _profileImageUrl == null
                  ? Icon(Icons.person, size: 60, color: Colors.grey[800])
                  : null,
            ),
            if (!_isEditMode)
              FloatingActionButton.small(
                onPressed: () => _pickImage(true),
                child: Icon(Icons.camera_alt),
                backgroundColor: Colors.pinkAccent,
              ),
          ],
        ),
        SizedBox(height: 15),
        Text(
          _isEditMode ? 'Your Profile' : 'Complete Your Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          _isEditMode
              ? 'View your professional details'
              : 'Add your professional details to attract more customers',
          style: TextStyle(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextInput(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        bool enabled = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      validator: enabled
          ? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      }
          : null,
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services Offered',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _serviceOptions.map((service) {
            return FilterChip(
              label: Text(service),
              selected: _selectedServices.contains(service),
              onSelected: _isEditMode
                  ? null
                  : (selected) {
                setState(() {
                  if (selected) {
                    _selectedServices.add(service);
                  } else {
                    _selectedServices.remove(service);
                  }
                });
              },
              selectedColor: Colors.pink[100],
              checkmarkColor: Colors.pink,
              labelStyle: TextStyle(
                color: _selectedServices.contains(service)
                    ? Colors.pink
                    : Colors.black,
              ),
              showCheckmark: true,
              shape: StadiumBorder(
                side: BorderSide(
                  color: _selectedServices.contains(service)
                      ? Colors.pink
                      : Colors.grey,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDesignsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'Your Designs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        if (!_isEditMode)
          ElevatedButton(
            onPressed: () => _pickImage(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Add Design', style: TextStyle(color: Colors.white)),
          ),
        SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: _designImages.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      _designImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    if (!_isEditMode)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.white.withOpacity(0.8),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => _removeDesignImage(index),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pinkAccent,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: _isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Text(
        'SAVE PROFILE',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tailor Profile'),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = false),
            ),
          if (_hasLocalImage && _isEditMode)
            IconButton(
              icon: Icon(Icons.cloud_upload),
              onPressed: _uploadToFirebaseStorage,
              tooltip: 'Upload to cloud',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(),
              SizedBox(height: 30),
              _buildTextInput('Shop Name', _shopNameController,
                  enabled: !_isEditMode),
              SizedBox(height: 20),
              _buildTextInput('Specialization', _specializationController,
                  enabled: !_isEditMode),
              SizedBox(height: 20),
              _buildTextInput('Experience (years)', _experienceController,
                  keyboardType: TextInputType.number,
                  enabled: !_isEditMode),
              SizedBox(height: 20),
              _buildTextInput('Price Range (e.g. 4000-5000)',
                  _priceRangeController,
                  enabled: !_isEditMode),
              SizedBox(height: 20),
              _buildTextInput('Bio', _bioController,
                  maxLines: 3, enabled: !_isEditMode),
              SizedBox(height: 20),
              _buildServicesSection(),
              _buildDesignsSection(),
              if (!_isEditMode) ...[
                SizedBox(height: 30),
                _buildSaveButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _priceRangeController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}