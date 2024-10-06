import 'dart:io';
import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PlantDiagnosisScreen extends StatefulWidget {
  @override
  _PlantDiagnosisScreenState createState() => _PlantDiagnosisScreenState();
}

class _PlantDiagnosisScreenState extends State<PlantDiagnosisScreen> {
  File? _image;
  String diagnosisResult = "";
  final picker = ImagePicker();
  bool isLoading=false;
  // Function to pick image from gallery
  Future<void> _getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  // Function to pick image from camera
  Future<void> _getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }


  Future<void> _uploadImage() async {
    String _responseText = "";
    if (_image == null) {
      print("No image selected.");
      return;
    }

    try {
      isLoading=true;
      setState(() {});

      /// Retrieve the selected image and handle it
      final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

      final prompt = TextPart("Please analyze this plant image. Identify the current health condition of the plant, including any diseases or deficiencies affecting it. Provide a detailed description of the issue, including the symptoms and possible causes. Additionally, offer specific suggestions or instructions on how to improve the plant's health, including recommended treatments or preventive measures in this language code ${Get.deviceLocale?.languageCode}");

      // Convert image to bytes for uploading
      final imageBytes = await _image?.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes!);  // Ensure proper MIME type for images

      try {
        // Send the image and prompt to the Vertex AI model
        final response = await model.generateContentStream([
          Content.multi([prompt, imagePart])
        ]);

        // Retrieve response text as it streams back
        await for (final chunk in response) {
          _responseText += chunk.text.toString();
        }
      } catch (e) {
        print("VertexAIError: ${e.toString()}");
      }

      print("responseText: ${_responseText}");
      isLoading=false;
      setState(() {});

    } catch (e) {
      isLoading=false;
      setState(() {});
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plant Diagnosis'),
      ),
      body: isLoading?Center(child: CircularProgressIndicator(),):
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Plant Image',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _getImageFromGallery,
                  icon: Icon(Icons.upload_file),
                  label: Text('Upload'),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _getImageFromCamera,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Camera'),
                ),
              ],
            ),
            SizedBox(height: 20),
            _image != null
                ? Image.file(
              _image!,
              height: 200,
            )
                : Text('No image selected'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Diagnose'),
            ),
            SizedBox(height: 20),
            Text(
              'Diagnosis Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            diagnosisResult.isNotEmpty
                ? Text(diagnosisResult)
                : Text('No diagnosis available.'),
          ],
        ),
      ),
    );
  }
}