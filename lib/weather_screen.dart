import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'models/Weather.dart';
import 'plant_status.dart'; // Ensure you import this if you're using PlantDiagnosisScreen

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final String apiKey = '5b96cae051124ddbfac74d58280e850e'; // Replace with your API key
  final String city = 'Hurghada'; // Replace with your city
  WeatherModel? weatherData; // Use the Weather model to store weather data
  bool isLoading = false;
  String _responseText = "";
  List<String> farmerTips = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      analyzeWeatherAndSuggestPlants();
    });
  }

  Future<void> analyzeWeatherAndSuggestPlants() async {
    // Fetch the weather data
    try {
      final weather = await _fetchWeather(city, apiKey);
      if (weather == null) {
        print("Failed to fetch weather data.");
        return;
      }

      // Store weather data in the state
      setState(() {
        weatherData = weather;
      });

      isLoading = true;
      setState(() {});

      // Retrieve the model for plant suggestions
      final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

      // Create a detailed prompt with weather information
      final prompt = TextPart(
          "Analyze the following weather conditions for plant recommendations: "
              "Temperature: ${weatherData?.main?.temp}°C, "
              "Humidity: ${weatherData?.main?.humidity}%, "
              "Weather: ${weatherData?.weather?.first.description}. "
              "Suggest plants that are most compatible with this weather, including specific care instructions. in this language code ${Get.deviceLocale?.languageCode}"
              "Also, provide a list of farmer tips to improve plant health in this language code ${Get.deviceLocale?.languageCode}."
      );

      try {
        // Send the weather details as a prompt to the Vertex AI model
        final response = await model.generateContentStream([Content.multi([prompt])]);

        // Clear previous response
        _responseText = ""; // Clear previous response

        // Retrieve response text as it streams back
        await for (final chunk in response) {
          _responseText += chunk.text.toString();
        }

        // Parse the response to extract farmer tips
        farmerTips = _extractFarmerTips(_responseText);

        // Log the response
        print("responseText: $_responseText");
        print("Farmer Tips: $farmerTips");

        // Update UI with the new farmer tips (You can save this to the state if needed)
        setState(() {
          // You might want to store farmerTips in a state variable for later use
        });

      } catch (e) {
        print("VertexAIError: ${e.toString()}");
      }

      isLoading = false;
      setState(() {});

    } catch (e) {
      print('Error fetching weather data: $e');
      isLoading = false;
      setState(() {});
    }
  }

// Function to extract farmer tips from the response text
  List<String> _extractFarmerTips(String responseText) {
    // Split the response text by newlines or any other separator you expect
    // Here we assume the tips are separated by line breaks
    List<String> tips = responseText.split('\n').map((tip) => tip.trim()).toList();
    return tips.where((tip) => tip.isNotEmpty).toList(); // Filter out any empty strings
  }


  // Fetch weather data based on city and API key
  Future<WeatherModel?> _fetchWeather(String city, String apiKey) async {
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> weatherJson = jsonDecode(response.body);
      return WeatherModel.fromJson(weatherJson); // Return a Weather model instance
    } else {
      print('Failed to load weather data: ${response.statusCode}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NASA Weather Stats'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Get.to(PlantDiagnosisScreen()); // Ensure PlantDiagnosisScreen is correctly defined
              },
              child: Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: weatherData == null
              ? Center(child: Text('No weather data available'))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weatherData?.main?.temp}°C',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Humidity: ${weatherData?.main?.humidity}%',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Weather: ${weatherData?.weather?.first.description}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              Text(
                'Plant Recommendations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(_responseText.isNotEmpty ? _responseText : 'No recommendations available.'),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              Text(
                'Farmer Tips',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                height: context.height*0.4,
                child: ListView.builder(
                  itemCount: farmerTips.length, // Count of the farmer tips
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0), // Add some vertical spacing
                      child: Text('${index + 1}. ${farmerTips[index]}'), // Display each tip with numbering
                    );
                  },
                ),
              ),

            ],
                    ),
                  ),
          ),
    );
  }
}
