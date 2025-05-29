import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarttailoring/user profile.dart';
import 'package:smarttailoring/LoginScreen.dart';
import 'package:smarttailoring/SignupScreen.dart';
import 'LadiesStyleScreen.dart';
import 'childstylescreen.dart';
import 'gentsstyle page.dart';
import 'Orderhistory.dart';
import 'Chatscreen.dart';

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // App Bar
          Container(
            color: Colors.white,
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 5,
              title: Text('Home', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.black),
                  onSelected: (value) {
                    if (value == "Profile") {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfile()));
                    } else if (value == "Login") {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                    } else if (value == "Signup") {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()));
                    } else if (value == "Logout") {
                      _showLogoutDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    _menuItem("Profile", Icons.person, Colors.orangeAccent),
                    _menuItem("Login", Icons.login, Colors.orange),
                    _menuItem("Signup", Icons.app_registration, Colors.green),
                    _menuItem("Logout", Icons.exit_to_app, Colors.blue),
                  ],
                ),
              ],
              centerTitle: false,
            ),
          ),

          // Banner Section
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Image.asset('assets/images/clothes.jpg', width: double.infinity, height: 200, fit: BoxFit.cover),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#Fashion with Smart Tailors',
                              style: TextStyle(fontSize: 18, color: Colors.white, backgroundColor: Colors.black45)),
                          SizedBox(height: 10),
                          Text('A name of fashion.',
                              style: TextStyle(fontSize: 14, color: Colors.white, backgroundColor: Colors.black45)),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text("Let’s Go", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Categories
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.1,
              children: [
                _buildCategory('Ladies', 'assets/images/Ladies.jpg', Colors.pinkAccent, context),
                _buildCategory('Gents', 'assets/images/gents.jpg', Colors.blueAccent, context),
                _buildCategory('Children', 'assets/images/children.jpg', Colors.orangeAccent, context),
                _buildCategory('Order now', 'assets/images/measurement.jpg', Colors.greenAccent, context),
              ],
            ),
          ),

          // Feedback Input
          Padding(padding: const EdgeInsets.all(10), child: FeedbackSection()),

          // Feedback Display
          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    print("Feedback container tapped!");
                  },
                  child: Padding(padding: EdgeInsets.all(10), child: FeedbackList()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      child: ListTile(leading: Icon(icon, color: color), title: Text(value)),
    );
  }

  Widget _buildCategory(String title, String imagePath, Color bgColor, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == "Ladies") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => LadiesStyleScreen()));
        } else if (title == "Gents") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => GentsStyleScreen()));
        } else if (title == "Children") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChildStyleScreen()));
        } else if (title == "Order now") {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => OrderHistoryScreen()));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please log in to order.")));
          }
        }
      },
      child: Padding(
        padding: EdgeInsets.all(6),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
            image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.fill),
          ),
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.all(8),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(5)),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout Confirmation'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }
}

// Feedback input widget
class FeedbackSection extends StatefulWidget {
  @override
  _FeedbackSectionState createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  double _rating = 0.0;
  TextEditingController _controller = TextEditingController();

  void _submitFeedback() async {
    if (_rating <= 0 || _controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please provide rating and feedback")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'rating': _rating,
        'feedback': _controller.text.trim(),
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Thank you for your feedback!")));

      _controller.clear();
      setState(() {
        _rating = 0.0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(labelText: "Your Feedback", border: OutlineInputBorder()),
          maxLines: 3,
        ),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.black),
              onPressed: () => setState(() => _rating = (index + 1).toDouble()),
            );
          }),
        ),
        Center(
          child: ElevatedButton(onPressed: _submitFeedback, child: Text("Submit Feedback")),
        ),
      ],
    );
  }
}

// Feedback display widget
class FeedbackList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('feedback').orderBy('timestamp', descending: true).limit(3).snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        var feedbacks = snapshot.data!.docs;

        return Column(
          children: feedbacks.map((doc) {
            return ListTile(
              leading: Icon(Icons.star, color: Colors.yellow),
              title: Text(doc['feedback']),
              subtitle: Text("Rating: ${doc['rating']} ⭐"),
            );
          }).toList(),
        );
      },
    );
  }
}
