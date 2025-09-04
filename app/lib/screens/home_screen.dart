import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'logs_screen.dart';
import 'control_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  bool _loading = false;
  Map<String, dynamic>? _result;

  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _imageFile = File(picked.path);
      _result = null;
    });
  }

  Future<void> _uploadAndDetect() async {
    if (_imageFile == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.detect(_imageFile!);
      setState(() {
        _result = res;
      });
    } catch (e) {
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $msg")));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openLogs() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LogsScreen()));
  }

  void _openControl() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ControlScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Sprayer"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            if (_imageFile == null)
              Placeholder(fallbackHeight: 200)
            else
              Image.file(_imageFile!, height: 240, fit: BoxFit.cover),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: Icon(Icons.camera_alt),
                  label: Text("Take Photo"),
                ),
                ElevatedButton.icon(
                  onPressed: _imageFile == null || _loading ? null : _uploadAndDetect,
                  icon: Icon(Icons.upload_file),
                  label: _loading ? Text("Detecting...") : Text("Detect"),
                )
              ],
            ),
            SizedBox(height: 16),
            if (_result != null) _buildResultCard(_result!),
            SizedBox(height: 20),
            Divider(),
            ListTile(
              leading: Icon(Icons.history),
              title: Text("Spray Logs"),
              onTap: _openLogs,
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Manual Control"),
              onTap: _openControl,
            ),
            ListTile(
              leading: Icon(Icons.network_check),
              title: Text("Fetch Current Command"),
              subtitle: Text("See what ESP32 would execute"),
              onTap: () async {
                try {
                  final cmd = await ApiService.getCommand();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Current Command"),
                      content: SingleChildScrollView(child: Text(cmd.toString())),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> res) {
    final prediction = res['prediction'] ?? <String, dynamic>{};
    final recommendation = res['recommendation'] ?? <String, dynamic>{};
    final log = res['log'] ?? <String, dynamic>{};

    // prediction from your Flask server is: { "disease": "...", "confidence": 0.xyz }
    final disease = prediction['disease'] ?? 'N/A';
    final confidence = (prediction['confidence'] != null) ? (prediction['confidence'] is num ? (prediction['confidence'] * 100).toStringAsFixed(2) + '%' : prediction['confidence'].toString()) : 'N/A';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Prediction", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text("Disease: $disease"),
            Text("Confidence: $confidence"),
            Divider(),
            Text("Recommendation", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text("Disease/Stage: ${recommendation['disease'] ?? recommendation['stage'] ?? 'N/A'}"),
            Text("Chemical: ${recommendation['chemical'] ?? 'N/A'}"),
            Text("Quantity: ${recommendation['quantity_per_200L'] ?? recommendation['quantity'] ?? 'N/A'}"),
            Divider(),
            Text("Command for ESP32", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text("Spray: ${log['spray'] == true ? 'YES' : 'NO'}"),
            Text("Servo index/angle: ${log['servo_index'] ?? log['servo_angle'] ?? 'N/A'}"),
            Text("Spray time (s): ${log['spray_time'] ?? log['pump_seconds'] ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }
}
