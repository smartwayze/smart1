import 'package:flutter/material.dart';
import 'package:smarttailoring/CustomDressScreen.dart';
import 'Orderhistory.dart';
import 'measurement form.dart';
import 'CustomDressScreen.dart';

class MeasurementForm extends StatefulWidget {
  final String chest, waist, hip, length, capri, shoulder,dressCode;

  const MeasurementForm({
    super.key,
    required this.chest,
    required this.waist,
    required this.hip,
    required this.length,
    required this.capri,
    required this.shoulder,
    required this.dressCode,
  });

  @override
  State<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  final TextEditingController dressCodeController = TextEditingController();

  final TextEditingController chestController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipController = TextEditingController();
  final TextEditingController sleeveController = TextEditingController();
  final TextEditingController caprilength = TextEditingController();
  final TextEditingController shoulderController = TextEditingController();


  String selectedGender = 'Female'; // default gender

  @override
  void initState() {
    super.initState();
    chestController.text = widget.chest;
    waistController.text = widget.waist;
    hipController.text = widget.hip;
    sleeveController.text = widget.length;
    caprilength.text = widget.capri;
    shoulderController.text = widget.shoulder;

    dressCodeController.text = widget.dressCode;
  }

  @override
  void dispose() {
    chestController.dispose();
    waistController.dispose();
    hipController.dispose();
    sleeveController.dispose();
    caprilength.dispose();
    shoulderController.dispose();dressCodeController.dispose();
    super.dispose();
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
                "Measurements",
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 10),
              const Text(
                'Predicted Measurements',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'You can edit the values if needed before proceeding.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              buildMeasurementField("Chest", chestController),
              const SizedBox(height: 15),
              buildMeasurementField("Waist", waistController),
              const SizedBox(height: 15),
              buildMeasurementField("Hips", hipController),
              const SizedBox(height: 15),
              buildMeasurementField("Shirt Length", sleeveController),
              const SizedBox(height: 15),
              buildMeasurementField("Capri length", shoulderController),
              const SizedBox(height: 15),
              buildMeasurementField("Shoulder", caprilength),
              const SizedBox(height: 15),
              buildMeasurementField("Dress Code", dressCodeController),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Save logic if needed
                    print("Saved values:");
                    print("Gender: $selectedGender");
                    print("Chest: ${chestController.text}");
                    print("Waist: ${waistController.text}");
                    print("Hips: ${hipController.text}");
                    print("Length: ${sleeveController.text}");
                    print("Capri: ${caprilength.text}");
                    print("Shoulder: ${shoulderController.text}");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  CustomDressScreen(userId: '', userName: '',),
                      ),
                    );
                  },
                  child: const Text(
                    "Next",
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

  Widget buildMeasurementField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),

        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
