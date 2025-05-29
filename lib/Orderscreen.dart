import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_apps/device_apps.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Homescreen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  bool isContactValid = false;
  String? selectedPaymentMethod;
  bool isProcessingPayment = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'JazzCash',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFF00A651),
      'deepLink': 'jazzcash://pay?amount=',
      'recipient': '03001234567',
      'package': 'com.techlogix.mobilinkcustomer',
      'playStoreUrl': 'https://play.google.com/store/apps/details?id=com.techlogix.mobilinkcustomer',
      'alternativeUrls': [
        'jazzcash://payment?amount=',
        'jazzcashmpk://payments?amount=',
        'jazzcash://transfer?amount=',
      ],
    },
    {
      'name': 'EasyPaisa',
      'icon': Icons.phone_android,
      'color': const Color(0xFF0056A3),
      'deepLink': 'easypaisa://payment?amount=',
      'recipient': '03451234567',
      'package': 'pk.com.telenor.easypaisa',
      'playStoreUrl': 'https://play.google.com/store/apps/details?id=pk.com.telenor.easypaisa',
      'alternativeUrls': [
        'easypaisa://pay?amount=',
        'easypaisa://transfer?amount=',
      ],
    },
    {
      'name': 'Cash on Delivery',
      'icon': Icons.local_shipping,
      'color': Colors.orange,
    }
  ];

  @override
  void initState() {
    super.initState();
    contactController.addListener(validateContactNumber);
  }

  @override
  void dispose() {
    contactController.removeListener(validateContactNumber);
    super.dispose();
  }

  void validateContactNumber() {
    setState(() {
      isContactValid = contactController.text.length == 11 &&
          RegExp(r'^\d{11}$').hasMatch(contactController.text);
    });
  }

  bool _isFormValid() {
    return nameController.text.isNotEmpty &&
        isContactValid &&
        addressController.text.isNotEmpty &&
        amountController.text.isNotEmpty &&
        selectedPaymentMethod != null;
  }

  Future<void> _processOrder() async {
    setState(() {
      isProcessingPayment = true;
    });

    try {
      // Get current user
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create order data
      final orderData = {
        'name': nameController.text,
        'contact': contactController.text,
        'address': addressController.text,
        'paymentMethod': selectedPaymentMethod,
        'amount': amountController.text,
        'status': selectedPaymentMethod == 'Cash on Delivery'
            ? 'Pending'
            : 'Payment Processing',
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add to custom_designs collection
      await _firestore.collection('customer_order_data').add(orderData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order placed successfully!"),
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to HomeScreen after showing success message
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Homescreen()),
              (Route<dynamic> route) => false,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to place order: ${e.toString()}"),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isProcessingPayment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                "Confirm Order",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("Enter Order Details",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              _buildTextField("Name", nameController, TextInputType.text),
              const SizedBox(height: 20),
              _buildTextField("Contact No", contactController, TextInputType.phone),
              const SizedBox(height: 20),
              _buildTextField("Address", addressController, TextInputType.text),
              const SizedBox(height: 20),
              _buildTextField("Amount (PKR)", amountController, TextInputType.number),
              const SizedBox(height: 30),
              const Text("Select Payment Method",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildPaymentMethodButton(paymentMethods[0])),
                  const SizedBox(width: 15),
                  Expanded(child: _buildPaymentMethodButton(paymentMethods[1])),
                ],
              ),
              const SizedBox(height: 15),
              _buildPaymentMethodButton(paymentMethods[2]),
              const SizedBox(height: 30),
              if (selectedPaymentMethod != null &&
                  selectedPaymentMethod != 'Cash on Delivery')
                _buildPaymentInstructions(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid() ? Colors.pinkAccent : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isFormValid() ? _processOrder : null,
                  child: isProcessingPayment
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Confirm Order",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPaymentMethodButton(Map<String, dynamic> method) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selectedPaymentMethod == method['name']
            ? method['color'].withOpacity(0.2)
            : Colors.white,
        side: BorderSide(
          color: selectedPaymentMethod == method['name']
              ? method['color']
              : Colors.grey,
          width: selectedPaymentMethod == method['name'] ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      onPressed: () {
        setState(() {
          selectedPaymentMethod = method['name'];
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(method['icon'], color: method['color']),
          const SizedBox(width: 8),
          Text(
            method['name'],
            style: TextStyle(
              color: Colors.black,
              fontWeight: selectedPaymentMethod == method['name']
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    final method =
    paymentMethods.firstWhere((m) => m['name'] == selectedPaymentMethod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text("${method['name']} Payment Instructions:",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._getPaymentInstructions(method['name']),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(method['icon'], color: Colors.white),
            label: Text("Pay with ${method['name']}"),
            onPressed: () => _launchPaymentApp(method),
            style: ElevatedButton.styleFrom(
              backgroundColor: method['color'],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _getPaymentInstructions(String? method) {
    switch (method) {
      case 'JazzCash':
        return [
          const Text("1. Open JazzCash app"),
          const Text("2. Select 'Send Money' option"),
          Text("3. Enter our JazzCash number: ${paymentMethods[0]['recipient']}"),
          Text("4. Enter amount: ${amountController.text.isNotEmpty ? amountController.text : '___'} PKR"),
          const Text("5. Confirm the transaction"),
        ];
      case 'EasyPaisa':
        return [
          const Text("1. Open EasyPaisa app"),
          const Text("2. Select 'Send Money' option"),
          Text("3. Enter our EasyPaisa number: ${paymentMethods[1]['recipient']}"),
          Text("4. Enter amount: ${amountController.text.isNotEmpty ? amountController.text : '___'} PKR"),
          const Text("5. Confirm payment"),
        ];
      default:
        return [const SizedBox.shrink()];
    }
  }

  Future<void> _launchPaymentApp(Map<String, dynamic> method) async {
    final amount = amountController.text.isNotEmpty ? amountController.text : '0';

    // Try all possible URL schemes
    final urlsToTry = [
      // Primary URL with all parameters
      '${method['deepLink']}$amount&recipient=${method['recipient']}',
      // Alternative URLs
      ...(method['alternativeUrls'] as List<String>).map((url) => '$url$amount&recipient=${method['recipient']}'),
      // Fallback to just opening the app
      method['deepLink'].replaceAll('?amount=', ''),
      ...(method['alternativeUrls'] as List<String>).map((url) => url.replaceAll('?amount=', '')),
    ];

    // Try each URL until one works
    for (final url in urlsToTry) {
      if (await canLaunchUrl(Uri.parse(url))) {
        try {
          await launchUrl(Uri.parse(url));
          return;
        } catch (e) {
          print('Failed to launch URL: $url, error: $e');
          continue;
        }
      }
    }

    // If no URL worked, check if app is installed
    final isInstalled = await _isAppInstalled(method['package']);
    if (!isInstalled) {
      // Open Play Store if app not installed
      if (method.containsKey('playStoreUrl')) {
        if (await canLaunchUrl(Uri.parse(method['playStoreUrl']))) {
          await launchUrl(Uri.parse(method['playStoreUrl']));
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${method['name']} app is not installed.'),
          action: SnackBarAction(
            label: 'Install',
            onPressed: () {
              if (method.containsKey('playStoreUrl')) {
                launchUrl(Uri.parse(method['playStoreUrl']));
              }
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      // App is installed but couldn't be launched - prompt user to open manually
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please open the app manually.'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<bool> _isAppInstalled(String packageName) async {
    try {
      final isInstalled = await DeviceApps.isAppInstalled(packageName);
      return isInstalled;
    } catch (e) {
      return false;
    }
  }
}