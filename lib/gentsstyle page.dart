import 'package:flutter/material.dart';

import 'Orderscreen.dart';
import 'modelscreen.dart';

class GentsStyleScreen extends StatelessWidget {
  GentsStyleScreen({super.key});

  final List<Map<String, dynamic>> styles = [
    {
      "name": "Casual Wear",
      "images": [
        "assets/mimages/mc1.jpeg",
        "assets/mimages/mc2.jpeg",
        "assets/mimages/mc3.jpeg",
        "assets/mimages/mc4.jpeg",
        "assets/mimages/mc5.jpeg",
        "assets/mimages/mc6.jpeg"
      ]
    },
    {
      "name": "Party Wear",
      "images": [
        "assets/mimages/mp1.jpeg",
        "assets/mimages/mp2.jpeg",
        "assets/mimages/mp3.jpeg",
        "assets/mimages/mp4.jpeg",
        "assets/mimages/mp5.jpeg",
        "assets/mimages/mp6.jpeg"
      ]
    },
    {
      "name": "Shalwar Qameez",
      "images": [
        "assets/mimages/msq1.jpeg",
        "assets/mimages/msq2.jpeg",
        "assets/mimages/msq3.jpeg",
        "assets/mimages/msq4.jpeg",
        "assets/mimages/msq5.jpeg",
        "assets/mimages/msq6.jpeg"
      ]
    },
    {
      "name": "Formal Wear",
      "images": [
        "assets/mimages/mfw1.jpeg",
        "assets/mimages/mfw2.jpeg",
        "assets/mimages/mfw3.jpeg",
        "assets/mimages/mfw4.jpeg",
        "assets/mimages/mfw5.jpeg",
        "assets/mimages/mfw6.jpeg"
      ]
    },
  ];

  int imageCounter = 1; // Start from 101

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.pinkAccent,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: AppBar(
            title: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Gents Style",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: ListView.builder(
                itemCount: styles.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            styles[index]["name"],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _buildImageGrid(context, styles[index]["images"]),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>HumanDetectorApp()));


              },
              style: ElevatedButton.styleFrom(

                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
              child: const Text(
                'pick your dress code & confirm  order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<String> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, imgIndex) {
        final currentImageNumber = imageCounter++; // Unique number for every image

        return GestureDetector(
          onTap: () {
            _showFullImage(context, images[imgIndex]);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Image.asset(
                  images[imgIndex],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Gents# $currentImageNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 6.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
