import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: MeasurementScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class MeasurementScreen extends StatefulWidget {
  @override
  _MeasurementScreenState createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  final Map<String, TextEditingController> controllers = {
    "Chest": TextEditingController(),
    "Waist": TextEditingController(),
    "Hips": TextEditingController(),
    "Shoulder": TextEditingController(),
    "Sleeve Length": TextEditingController(),
    "Neck": TextEditingController(),
    "Thigh": TextEditingController(),
    "Inseam": TextEditingController(),
  };

  String selectedSize = "Small";
  Map<String, String> selectedUnits = {};

  @override
  void initState() {
    super.initState();
    controllers.keys.forEach((key) {
      selectedUnits[key] = "CM";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
          child: AppBar(
            backgroundColor: Colors.pinkAccent,
            title: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Body Measurement",
                style: TextStyle(color: Colors.white),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Measurements",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Please enter your measurements carefully to get the best fit.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Divider(thickness: 1, color: Colors.grey[400]),
            SizedBox(height: 10),
            ...controllers.entries.map((entry) => buildMeasurementRow(entry.key, entry.value)),

            SizedBox(height: 20),
            Text("Select Dress Size", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["Small", "Medium", "Large", "X-Large"].map((size) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedSize = size;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedSize == size ? Colors.pinkAccent : Colors.grey[300],
                    foregroundColor: selectedSize == size ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Adjust the radius as needed
                    ),
                  ),
                  child: Text(size),
                );
              }).toList(),
            ),

            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controllers.forEach((key, controller) {
                    print("$key: ${controller.text} ${selectedUnits[key]}");
                  });
                  print("Selected Size: $selectedSize");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Adjust the radius as needed
                  ),
                ),
                child: Text(
                  "Next",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMeasurementRow(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
          ),
          SizedBox(width: 10),
          ToggleButtons(
            isSelected: [selectedUnits[label] == "CM", selectedUnits[label] == "INCH"],
            onPressed: (index) {
              setState(() {
                selectedUnits[label] = index == 0 ? "CM" : "INCH";
              });
            },
            borderRadius: BorderRadius.circular(10),
            selectedColor: Colors.white,
            fillColor: Colors.pinkAccent,
            color: Colors.black,
            children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("CM")),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("INCH")),
            ],
          ),
        ],
      ),
    );
  }
}
