import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

// Simple test function to verify Dialogflow connection
Future<void> testDialogflowConnection() async {
  try {
    print('Testing Dialogflow connection...');
    
    // Load credentials
    final configString = await rootBundle.loadString('assets/dialogflow_config.json');
    final serviceAccount = json.decode(configString);
    
    print('Loaded service account for: ${serviceAccount['client_email']}');
    
    // Get access token
    final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
    final client = await clientViaServiceAccount(
      credentials, 
      ['https://www.googleapis.com/auth/cloud-platform']
    );
    
    final accessCredentials = await obtainAccessCredentialsViaServiceAccount(
      credentials,
      ['https://www.googleapis.com/auth/cloud-platform'],
      client,
    );
    
    final accessToken = accessCredentials.accessToken.data;
    print('Successfully obtained access token');
    
    // Test API call
    const projectId = 'umangly-app';
    const sessionId = 'test-session-123';
    final url = 'https://dialogflow.googleapis.com/v2/projects/$projectId/agent/sessions/$sessionId:detectIntent';
    
    final requestBody = {
      'queryInput': {
        'text': {
          'text': 'Hello Arav, I need motivation',
          'languageCode': 'en',
        }
      }
    };
    
    print('Making test API call to: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode(requestBody),
    );
    
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final fulfillmentText = responseData['queryResult']['fulfillmentText'];
      print('SUCCESS! Dialogflow response: $fulfillmentText');
    } else {
      print('ERROR: ${response.statusCode} - ${response.body}');
    }
    
    client.close();
    
  } catch (e) {
    print('Test failed with error: $e');
  }
}