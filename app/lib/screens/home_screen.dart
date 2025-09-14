import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'logs_screen.dart';
import 'control_screen.dart';
import 'gemini_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $msg"),
          backgroundColor: Colors.red,
        )
      );
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
        title: Text("Smart Sprayer", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!,
              Colors.lightGreen[50]!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Image Capture Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Plant Disease Detection",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: _imageFile == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 40, color: Colors.grey[500]),
                                    SizedBox(height: 8),
                                    Text("No image captured", style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: Icon(Icons.camera_alt, size: 20),
                            label: Text("Capture"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _imageFile == null || _loading ? null : _uploadAndDetect,
                            icon: _loading 
                                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(Icons.upload_file, size: 20),
                            label: _loading ? Text("Processing...") : Text("Detect"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Results Section
              if (_result != null) _buildResultCard(_result!),
              
              SizedBox(height: 20),
              
              // Options Grid
              Text(
                "System Controls",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _buildOptionCard(
                    icon: Icons.history,
                    title: "Spray Logs",
                    color: Colors.orange[700]!,
                    onTap: _openLogs,
                  ),
                  _buildOptionCard(
                    icon: Icons.settings,
                    title: "Manual Control",
                    color: Colors.green[700]!,
                    onTap: _openControl,
                  ),
                  _buildOptionCard(
                    icon: Icons.health_and_safety,
                    title: "Spray Status",
                    color: Colors.blue[700]!,
                    onTap: () async {
                      try {
                        final cmd = await ApiService.getCommand();
                        // Show only spray status to user
                        final sprayStatus = cmd['spray'] == true ? 'ACTIVE' : 'INACTIVE';
                        final chemical = cmd['chemical'] ?? 'Not specified';
                        
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Current Spray Status", style: TextStyle(color: Colors.green[800])),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Spray: $sprayStatus", style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text("Chemical: $chemical"),
                                if (cmd['timestamp'] != null) ...[
                                  SizedBox(height: 8),
                                  Text("Last updated: ${cmd['timestamp']}", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ]
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context), 
                                child: Text("OK", style: TextStyle(color: Colors.green[700])),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: ${e.toString()}"),
                            backgroundColor: Colors.red,
                          )
                        );
                      }
                    },
                  ),
                  _buildOptionCard(
                    icon: Icons.info_outline,
                    title: "Disease Info",
                    subtitle: "AI-powered explanations",
                    color: Colors.purple[700]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GeminiScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              SizedBox(height: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> res) {
    final prediction = res['prediction'] ?? <String, dynamic>{};
    final recommendation = res['recommendation'] ?? <String, dynamic>{};

    final disease = prediction['disease'] ?? 'N/A';
    final confidence = (prediction['confidence'] != null) 
        ? (prediction['confidence'] is num 
            ? (prediction['confidence'] * 100).toStringAsFixed(2) + '%' 
            : prediction['confidence'].toString()) 
        : 'N/A';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Detection Results", 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 12),
            Text("Prediction", style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text("Disease: $disease"),
            Text("Confidence: $confidence"),
            Divider(),
            Text("Recommendation", style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text("Disease/Stage: ${recommendation['disease'] ?? recommendation['stage'] ?? 'N/A'}"),
            Text("Chemical: ${recommendation['chemical'] ?? 'N/A'}"),
            Text("Quantity: ${recommendation['amount'] ?? recommendation['quantity'] ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }
}