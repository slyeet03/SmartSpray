import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiService {
  // Change this to your laptop IP + port where Flask server is running
  static String baseUrl = "http://10.0.2.2:5001";

  /// Upload image to /detect (multipart/form-data)
  static Future<Map<String, dynamic>> detect(File imageFile) async {
    final uri = Uri.parse("$baseUrl/detect");
    final request = http.MultipartRequest('POST', uri);

    final stream = http.ByteStream(imageFile.openRead());
    final length = await imageFile.length();

    final multipartFile = http.MultipartFile(
      'image',
      stream,
      length,
      filename: path.basename(imageFile.path),
    );

    request.files.add(multipartFile);

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Server responded ${resp.statusCode}: ${resp.body}");
    }
  }

  /// Get logs
  static Future<List<dynamic>> getLogs() async {
    final uri = Uri.parse("$baseUrl/logs");
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as List<dynamic>;
    } else {
      throw Exception("Failed to fetch logs: ${resp.statusCode}");
    }
  }

  /// Send manual override command to server
  /// payload example: { "spray": true, "servo_index": 1, "pump_seconds": 2.5, "chemical": "Mancozeb" }
  static Future<Map<String, dynamic>> sendOverride(Map<String, dynamic> payload) async {
    final uri = Uri.parse("$baseUrl/override");
    final resp = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload));
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Override failed: ${resp.statusCode} ${resp.body}");
    }
  }

  /// Fetch the current command (what the ESP32 would read)
  static Future<Map<String, dynamic>> getCommand() async {
    final uri = Uri.parse("$baseUrl/command");
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch command: ${resp.statusCode}");
    }
  }
}

