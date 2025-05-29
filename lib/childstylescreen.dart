import 'package:flutter/material.dart';

import 'Orderscreen.dart';
import 'modelscreen.dart';

class ChildStyleScreen extends StatelessWidget {
  const ChildStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> styles = [
      {
        "name": "Casual Wear",
        "images": [
          "assets/images/ccc1.jpeg",
          "assets/images/ccc2.jpg",
          "assets/images/ccc3.jpeg",
          "assets/images/ccc4.jpeg",
          "assets/images/ccc5.jpeg",
          "assets/images/ccc6.jpeg"
        ]
      },
      {
        "name": "Party Wear",
        "images": [
          "assets/images/cp1.jpeg",
          "assets/images/cp2.jpeg",
          "assets/images/cp3.jpeg",
          "assets/images/cp4.jpeg",
          "assets/images/cp5.jpeg",
          "assets/images/cp6.jpeg"
        ]
      },
      {
        "name": "Formal Wear",
        "images": [
          "assets/images/cf1.jpeg",
          "assets/images/cf2.jpeg",
          "assets/images/cf3.jpeg",
          "assets/images/cf4.jpeg",
          "assets/images/cf5.jpeg",
          "assets/images/cf6.jpeg"
        ]
      },
      {
        "name": "Comfy Wear",
        "images": [
          "assets/images/cc1.jpeg",
          "assets/images/cc2.jpeg",
          "assets/images/cc3.jpeg",
          "assets/images/cc4.jpeg",
          "assets/images/cc5.jpeg",
          "assets/images/cc6.jpeg"
        ]
      },
    ];

    int globalImageCounter = 1;

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
                "Children Style",
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
                          child: Column(
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: styles[index]["images"].length,
                                itemBuilder: (context, imgIndex) {
                                  int currentNumber = globalImageCounter++;

                                  return GestureDetector(
                                    onTap: () {
                                      _showFullImage(context, styles[index]["images"][imgIndex]);
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Stack(
                                        children: [
                                          Image.asset(
                                            styles[index]["images"][imgIndex],
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
                                                'Child# $currentNumber',
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
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),Padding(
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
