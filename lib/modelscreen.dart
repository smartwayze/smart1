import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import 'measurement form.dart';


class HumanDetectorApp extends StatefulWidget {
  const HumanDetectorApp({super.key});

  @override
  State<HumanDetectorApp> createState() => _HumanDetectorAppState();
}

class _HumanDetectorAppState extends State<HumanDetectorApp> {
  File? _image;
  String _result = 'Select full body image first';
  bool _isLoading = false;
  bool _humanDetected = false;
  String? _error;

  final picker = ImagePicker();
  final int inputSize = 640;
  final double threshold = 0.5;

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dressCodeController = TextEditingController();

  late HumanDetectionService _detectionService;
  late MeasurementService _measurementService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _detectionService = HumanDetectionService();
      _measurementService = MeasurementService();

      await _detectionService.loadModel();
      await _measurementService.loadModel();
    } catch (e) {
      _updateErrorState('Model load failed: ${e.toString()}');
    }
  }

  Future<void> pickImage(ImageSource source) async {
    if (_isLoading) return;

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _result = 'Processing...';
        _error = null;
        _isLoading = true;
        _humanDetected = false;
      });

      final (detected, result) = await _detectionService.detectHuman(File(pickedFile.path));
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
        _humanDetected = detected;
      });
    } catch (e) {
      _updateErrorState('Image selection failed: ${e.toString()}');
    }
  }

  void _predictMeasurements() async {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final dressCode = _dressCodeController.text.trim();

    if (height == null || weight == null || dressCode.isEmpty) {
      _updateErrorState('Please enter valid height, weight, and dress code.');
      return;
    }

    try {
      final measurements = await _measurementService.predict(height, weight);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MeasurementForm(
            chest: measurements[0].toStringAsFixed(2),
            waist: measurements[1].toStringAsFixed(2),
            hip: measurements[2].toStringAsFixed(2),
            length: measurements[3].toStringAsFixed(2),
            shoulder: measurements[4].toStringAsFixed(2),
            capri: measurements[5].toStringAsFixed(2),
            dressCode: dressCode,
          ),
        ),
      );
    } catch (e) {
      _updateErrorState('Measurement prediction failed: ${e.toString()}');
    }
  }


  void _updateErrorState(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _result = 'Error';
      _isLoading = false;
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Capture from Camera'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _dressCodeController.dispose();
    _detectionService.dispose();
    _measurementService.dispose();
    super.dispose();
  }

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
                "Body Measurements",
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _image != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  )
                      : const Center(child: Text('Tap to select image')),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Processing image...'),
                  ],
                ),
              if (!_isLoading)
                Text(
                  _result,
                  style: TextStyle(
                    fontSize: 18,
                    color: _result.contains('✅') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _heightController,
                enabled: _humanDetected,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _weightController,
                enabled: _humanDetected,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _dressCodeController,
                enabled: _humanDetected,
                decoration: const InputDecoration(
                  labelText: 'Dress Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _humanDetected ? _predictMeasurements : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.pink.shade400,
                ),
                child: const Text('Predict Measurements',style: TextStyle(color:Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HumanDetectionService {
  late Interpreter _interpreter;
  final int inputSize = 640;
  final double threshold = 0.5;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/model_quantized.tflite');
  }

  Future<(bool, String)> detectHuman(File imageFile) async {
    final rawBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(rawBytes);
    if (decodedImage == null) return (false, 'Image decoding failed');

    final resized = img.copyResize(decodedImage, width: inputSize, height: inputSize);
    final input = _imageToByteListFloat32(resized, inputSize);

    final outputShape = _interpreter.getOutputTensor(0).shape;
    final outputBuffer = List<List<List<double>>>.generate(
      outputShape[0],
          (_) => List<List<double>>.generate(
        outputShape[1],
            (_) => List<double>.filled(outputShape[2], 0.0),
      ),
    );

    _interpreter.run(input, outputBuffer);

    double maxConfidence = 0;
    bool humanDetected = false;

    for (int i = 0; i < outputBuffer[0][0].length; i++) {
      final confidence = outputBuffer[0][4][i];
      final classId = _getClassId(outputBuffer[0], i);
      if (classId == 0 && confidence > threshold) {
        humanDetected = true;
        if (confidence > maxConfidence) maxConfidence = confidence;
      }
    }

    if (humanDetected) {
      return (true, '✅ Human ');
    } else {
      return (false, '❌ No Human found. Capture again.');
    }
  }

  int _getClassId(List<List<double>> output, int idx) {
    int start = 5;
    double maxScore = -1;
    int maxIndex = -1;
    for (int i = start; i < output.length; i++) {
      if (output[i][idx] > maxScore) {
        maxScore = output[i][idx];
        maxIndex = i - start;
      }
    }
    return maxIndex;
  }

  Uint8List _imageToByteListFloat32(img.Image image, int size) {
    final buffer = Float32List(1 * size * size * 3);
    int pixelIndex = 0;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = img.getRed(pixel) / 255.0;
        buffer[pixelIndex++] = img.getGreen(pixel) / 255.0;
        buffer[pixelIndex++] = img.getBlue(pixel) / 255.0;
      }
    }
    return buffer.buffer.asUint8List();
  }

  void dispose() {
    _interpreter.close();
  }
}

class MeasurementService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/measurement model.tflite');
  }

  Future<List<double>> predict(double height, double weight) async {
    final input = [[height, weight]];
    final output = List.filled(1 * 6, 0.0).reshape([1, 6]);
    _interpreter.run(input, output);
    return output[0];
  }

  void dispose() {
    _interpreter.close();
   }
}
