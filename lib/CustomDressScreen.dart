import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Orderscreen.dart';

class CustomDressScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const CustomDressScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<CustomDressScreen> createState() => _CustomDressScreenState();
}

class _CustomDressScreenState extends State<CustomDressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Form fields
  String _category = '';
  String _description = '';
  String _requirements = '';
  String _selectedTailor = '';
  List<File> _localImages = [];
  List<String> _imageUrls = [];

  // Tailor data
  List<Map<String, dynamic>> _tailors = [];
  bool _isLoadingTailors = true;

  @override
  void initState() {
    super.initState();
    _loadTailors();
  }

  Future<void> _loadTailors() async {
    try {
      final snapshot = await _firestore.collection('tailors').get();
      setState(() {
        _tailors = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'userId': data['userId'] ?? doc.id,
            'shopName': data['shopName'] ?? 'Unknown Tailor',
            'specialization': data['specialization'] ?? 'General Tailor',
            'bio': data['bio'] ?? 'No bio provided',
            'experience': data['experience']?.toString() ?? '0',
            'priceRange': data['priceRange'] ?? 'Not specified',
            'rating': data['rating']?.toString() ?? '0',
            'reviews': data['reviews'] ?? '',
            'services': data['services'] ?? [],
            'designImages': data['designImages'] ?? [],
            'hasLocalImage': data['hasLocalImage'] ?? false,
            'profileImagePath': data['profileImagePath'] ?? '',
          };
        }).toList();
        _isLoadingTailors = false;
      });
    } catch (e) {
      print('Error loading tailors: $e');
      setState(() => _isLoadingTailors = false);
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _localImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _uploadImages() async {
    _imageUrls.clear();
    for (var image in _localImages) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
        final ref = _storage.ref().child('custom_designs/$fileName');
        await ref.putFile(image);
        _imageUrls.add(await ref.getDownloadURL());
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  Future<void> _saveDesign() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Get the selected tailor's shopName
    String shopName = '';
    if (_selectedTailor.isNotEmpty) {
      final selectedTailor = _tailors.firstWhere(
            (tailor) => tailor['id'] == _selectedTailor || tailor['userId'] == _selectedTailor,
        orElse: () => {},
      );
      shopName = selectedTailor['shopName'] ?? 'Unknown Shop';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _uploadImages();

      // Create the document data with all required fields
      final designData = {
        'userId': widget.userId, // Use the widget.userId passed to the screen
        'userName': widget.userName, // Use the widget.userName passed to the screen
        'category': _category,
        'description': _description,
        'requirements': _requirements,
        'selectedTailor': _selectedTailor,
        'shopName': shopName,
        'status': 'Pending',
        'imageUrls': _imageUrls,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await _firestore.collection('custom_designs').add(designData);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to OrderScreen after successful submission
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreen(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Design submitted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showTailorProfile(Map<String, dynamic> tailor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
           decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: tailor['profileImagePath'] != null &&
                            tailor['profileImagePath'].isNotEmpty
                            ? FileImage(File(tailor['profileImagePath']))
                            : null,
                        child: tailor['profileImagePath'] == null ||
                            tailor['profileImagePath'].isEmpty
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tailor['shopName'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tailor['specialization'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        tailor['rating'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        tailor['priceRange'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                if (tailor['bio'] != null && tailor['bio'].isNotEmpty)
                  _buildInfoSection('About', tailor['bio']),
                if (tailor['services'] != null && tailor['services'].isNotEmpty) ...[
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (tailor['services'] as List).map((service) => Chip(
                      label: Text(service.toString()),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                if (tailor['designImages'] != null && tailor['designImages'].isNotEmpty) ...[
                  Text(
                    'Previous Designs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tailor['designImages'].length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              tailor['designImages'][index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTailor = tailor['userId'] ?? tailor['id'];
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected ${tailor['shopName']}')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('SELECT THIS TAILOR'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Dress Design'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Design Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['Wedding', 'Casual', 'Formal', 'Traditional', 'Other']
                            .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )).toList(),
                        onChanged: (value) => setState(() => _category = value!),
                        validator: (value) =>
                        value == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        onSaved: (value) => _description = value ?? '',
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a description' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Requirements',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        onSaved: (value) => _requirements = value ?? '',
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Images'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _pickImages,
                      ),
                      const SizedBox(height: 10),
                      if (_localImages.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _localImages.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _localImages[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Available Tailors',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoadingTailors)
              const Center(child: CircularProgressIndicator())
            else if (_tailors.isEmpty)
              const Text('No tailors available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tailors.length,
                itemBuilder: (context, index) {
                  final tailor = _tailors[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: tailor['profileImagePath'] != null &&
                            tailor['profileImagePath'].isNotEmpty
                            ? FileImage(File(tailor['profileImagePath']))
                            : null,
                        child: tailor['profileImagePath'] == null ||
                            tailor['profileImagePath'].isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        tailor['shopName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(tailor['rating']),
                              const SizedBox(width: 16),
                              Text(tailor['priceRange']),
                            ],
                          ),
                          if (tailor['designImages'] != null && tailor['designImages'].isNotEmpty)
                            Text(
                              '${tailor['designImages'].length} designs',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: _selectedTailor == tailor['id']
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () => _showTailorProfile(tailor),
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveDesign,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SUBMIT DESIGN',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}