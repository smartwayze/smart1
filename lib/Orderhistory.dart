import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userRole;
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> orders = [];
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'User not logged in';
          isLoading = false;
        });
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userRole = 'user';
          userProfile = userDoc.data();
        });
        await _fetchUserOrders(user.uid);
      } else {
        final tailorDoc = await _firestore.collection('tailors').doc(user.uid).get();
        if (tailorDoc.exists) {
          setState(() {
            userRole = 'tailor';
            userProfile = tailorDoc.data();
          });
          await _fetchTailorOrders(user.uid);
        } else {
          setState(() {
            errorMessage = 'User profile not found';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching user data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserOrders(String userId) async {
    try {
      final ordersQuery = _firestore.collection('customer_order_data')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      final querySnapshot = await ordersQuery.get();
      List<Map<String, dynamic>> tempOrders = [];

      for (var doc in querySnapshot.docs) {
        final orderData = doc.data();
        final designId = orderData['document'] ?? '';

        // Get design data from custom_designs
        Map<String, dynamic> designData = {};
        if (designId.isNotEmpty) {
          try {
            final designDoc = await _firestore.collection('custom_designs').doc(designId).get();
            if (designDoc.exists) {
              designData = designDoc.data() ?? {};
              print('Design data for $designId: $designData'); // Debug print
            }
          } catch (e) {
            print('Error fetching design $designId: $e');
          }
        }

        // Get user data
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() ?? {};

        // Get review data if order is completed
        Map<String, dynamic> reviewData = {};
        if ((designData['status'] ?? '').toString().toLowerCase() == 'completed') {
          final reviewQuery = await _firestore.collection('reviews')
              .where('orderId', isEqualTo: doc.id)
              .limit(1)
              .get();
          if (reviewQuery.docs.isNotEmpty) {
            reviewData = reviewQuery.docs.first.data();
          }
        }

        tempOrders.add({
          'id': doc.id,
          ...orderData,
          'userName': userData['name'] ?? 'Unknown',
          'shopName': orderData['shopName'] ?? designData['shopName'] ?? 'No shop', // Changed
          'category': orderData['category'] ?? designData['category'] ?? 'No category', // Changed
          'status': designData['status'] ?? 'Pending',
          'paymentMethod': orderData['paymentMethod'] ?? 'Not specified',
          'amount': orderData['amount']?.toString() ?? 'N/A',
          'createdAt': (orderData['timestamp'] as Timestamp).toDate(),
          'updatedAt': orderData.containsKey('updatedAt')
              ? (orderData['updatedAt'] as Timestamp).toDate()
              : null,
          'review': reviewData,
        });
      }

      setState(() {
        orders = tempOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading orders: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTailorOrders(String tailorId) async {
    try {
      final querySnapshot = await _firestore.collection('customer_order_data')
          .where('selectedTailor', isEqualTo: tailorId)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> tempOrders = [];

      for (var doc in querySnapshot.docs) {
        final orderData = doc.data();
        final designId = orderData['document'] ?? '';

        // Get design data from custom_designs
        Map<String, dynamic> designData = {};
        if (designId.isNotEmpty) {
          try {
            final designDoc = await _firestore.collection('custom_designs').doc(designId).get();
            if (designDoc.exists) {
              designData = designDoc.data() ?? {};
              print('Design data for $designId: $designData'); // Debug print
            }
          } catch (e) {
            print('Error fetching design $designId: $e');
          }
        }

        // Get customer data
        Map<String, dynamic> customerData = {};
        final customerDoc = await _firestore.collection('users').doc(orderData['userId']).get();
        if (customerDoc.exists) {
          customerData = customerDoc.data() ?? {};
        }

        // Get review data if order is completed
        Map<String, dynamic> reviewData = {};
        if ((designData['status'] ?? '').toString().toLowerCase() == 'completed') {
          final reviewQuery = await _firestore.collection('reviews')
              .where('orderId', isEqualTo: doc.id)
              .limit(1)
              .get();
          if (reviewQuery.docs.isNotEmpty) {
            reviewData = reviewQuery.docs.first.data();
          }
        }

        tempOrders.add({
          'id': doc.id,
          ...orderData,
          'userName': customerData['name'] ?? 'Unknown Customer',
          'shopName': orderData['shopName'] ?? designData['shopName'] ?? 'No shop', // Changed
          'category': orderData['category'] ?? designData['category'] ?? 'No category', // Changed
          'status': designData['status'] ?? 'Pending',
          'paymentMethod': orderData['paymentMethod'] ?? 'Not specified',
          'amount': orderData['amount']?.toString() ?? 'N/A',
          'createdAt': (orderData['timestamp'] as Timestamp).toDate(),
          'updatedAt': orderData.containsKey('updatedAt')
              ? (orderData['updatedAt'] as Timestamp).toDate()
              : null,
          'review': reviewData,
        });
      }

      setState(() {
        orders = tempOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching tailor orders: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'payment processing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildReviewSection(Map<String, dynamic>? review) {
    if (review == null || review.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 20),
        Text(
          'Customer Review:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            SizedBox(width: 8),
            Text(
              '${review['rating']?.toStringAsFixed(1) ?? '0.0'}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (review['comment'] != null && review['comment'].isNotEmpty)
          Text(
            review['comment'],
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        SizedBox(height: 8),
        Text(
          'Reviewed on: ${DateFormat('MMM dd, yyyy').format((review['timestamp'] as Timestamp).toDate())}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (userProfile != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: ListTile(
                title: Text(
                  userProfile?['name'] ?? 'No Name',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  userRole == 'user' ? 'Customer' : 'Professional Tailor',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
          if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            )
          else if (orders.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No orders found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${order['id'].substring(0, 8)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order['status'] ?? 'Pending')
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order['status'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: _getStatusColor(order['status'] ?? 'Pending'),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.payment, size: 18, color: Colors.blueGrey),
                                  SizedBox(width: 8),
                                  Text(
                                    '${order['paymentMethod']}',
                                    style: TextStyle(color: Colors.blueGrey),
                                  ),
                                  Spacer(),
                                  Text(
                                    'Amount: RS ${order['amount']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (order['status']?.toLowerCase() == 'completed')
                              _buildReviewSection(order['review']),
                            Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Placed: ${DateFormat('MMM dd, yyyy - hh:mm a').format(order['createdAt'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (order['updatedAt'] != null)
                                  Text(
                                    'Updated: ${DateFormat('MMM dd, yyyy').format(order['updatedAt'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}