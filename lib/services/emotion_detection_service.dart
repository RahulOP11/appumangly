import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class EmotionDetectionService {
  static const String _baseUrl = 'http://192.168.50.181:5000';
  static const List<String> emotions = [
    'angry', 'disgust', 'fear', 'happy', 'sad', 'surprise', 'neutral'
  ];
  
  static Future<String> detectEmotion(CameraImage image) async {
    try {
      print('=== EMOTION DETECTION START ===');
      print('Camera image: ${image.width}x${image.height}, format: ${image.format.group}');
      
      // Immediately copy image data to prevent garbage collection
      final imageData = _copyImageData(image);
      print('Image data copied successfully');
      
      // Convert CameraImage to JPEG base64
      final base64Image = await _convertCameraImageToJpegBase64(imageData);
      print('Image converted to base64, length: ${base64Image.length}');
      
      // Prepare the request body
      final requestBody = jsonEncode({
        'image_data': base64Image,
        'format': 'jpeg'
      });
      
      print('Sending request to Flask API...');
      
      // Make HTTP request to Flask API
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 15));
      
      print('Received response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          final emotion = jsonResponse['emotion'] ?? 'neutral';
          print('Detected emotion: $emotion');
          return emotion;
        } else {
          print('API error: ${jsonResponse['error']}');
          return 'neutral';
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        return 'neutral';
      }
    } catch (e) {
      print('Error in emotion detection: $e');
      return 'neutral';
    }
  }
  
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('API health check failed: $e');
      return false;
    }
  }
  
  static Map<String, dynamic> _copyImageData(CameraImage image) {
    // Copy image data to prevent garbage collection
    final planes = <Map<String, dynamic>>[];
    
    for (final plane in image.planes) {
      // Create a copy of the bytes to prevent garbage collection
      final copiedBytes = Uint8List.fromList(plane.bytes);
      planes.add({
        'bytes': copiedBytes,
        'bytesPerPixel': plane.bytesPerPixel,
        'bytesPerRow': plane.bytesPerRow,
      });
    }
    
    return {
      'width': image.width,
      'height': image.height,
      'format': image.format.group,
      'planes': planes,
    };
  }
  
  static Future<String> _convertCameraImageToJpegBase64(Map<String, dynamic> imageData) async {
    try {
      final int width = imageData['width'];
      final int height = imageData['height'];
      final List<dynamic> planes = imageData['planes'];
      
      print('Converting image: ${width}x${height}');
      
      // Get Y plane (luminance) - this contains the main image data
      final yPlane = planes[0];
      final Uint8List yBytes = yPlane['bytes'];
      
      print('Y plane bytes length: ${yBytes.length}');
      
      // Create an RGB image using the Y channel (grayscale converted to RGB)
      final img.Image image = img.Image(width: width, height: height);
      
      int yIndex = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (yIndex < yBytes.length) {
            final int yValue = yBytes[yIndex];
            // Convert grayscale to RGB for better face detection
            final pixel = img.ColorRgb8(yValue, yValue, yValue);
            image.setPixel(x, y, pixel);
            yIndex++;
          }
        }
      }
      
      print('Created image object, encoding to JPEG...');
      
      // Encode as JPEG with high quality for better face detection
      final List<int> jpegBytes = img.encodeJpg(image, quality: 90);
      
      print('JPEG encoded size: ${jpegBytes.length} bytes');
      
      final String base64String = base64Encode(jpegBytes);
      print('Base64 string length: ${base64String.length}');
      
      return base64String;
    } catch (e) {
      print('Error converting camera image to JPEG: $e');
      rethrow;
    }
  }
  
}