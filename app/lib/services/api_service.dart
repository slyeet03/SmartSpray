import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiService {
  // 👇 Change this IP to your laptop's LAN IP if testing on a real device
  // Use 10.0.2.2:5001 ONLY if running on Android emulator
  static String baseUrl = "http://10.230.158.89:5001"; // <-- set your laptop IP:port

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

  /// Get logs (returns list)
  static Future<List<dynamic>> getLogs() async {
    final uri = Uri.parse("$baseUrl/logs");
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as List<dynamic>;
    } else {
      throw Exception("Failed to fetch logs: ${resp.statusCode}");
    }
  }

  /// Fetch the latest command/log (what the ESP32 would execute)
  /// Uses the existing /logs route with ?last=1 to avoid adding new backend endpoints.
  static Future<Map<String, dynamic>> getCommand() async {
    final uri = Uri.parse("$baseUrl/logs?last=1");
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List<dynamic>;
      if (list.isNotEmpty) {
        return list.last as Map<String, dynamic>; // last entry is the newest (server returns chronological)
      } else {
        return <String, dynamic>{};
      }
    } else {
      throw Exception("Failed to fetch command: ${resp.statusCode}");
    }
  }

  /// Send manual override command to server
  /// payload example:
  /// {
  ///   "spray": true,
  ///   "spray_time": 5,
  ///   "servo_index": 1,
  ///   "chemical": "Mancozeb"
  /// }
  static Future<Map<String, dynamic>> sendOverride(Map<String, dynamic> payload) async {
    final uri = Uri.parse("$baseUrl/override");
    final resp = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: json.encode(payload),
    );
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Override failed: ${resp.statusCode} ${resp.body}");
    }
  }
}
