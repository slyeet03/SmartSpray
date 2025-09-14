import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GeminiScreen extends StatefulWidget {
  @override
  _GeminiScreenState createState() => _GeminiScreenState();
}

class _GeminiScreenState extends State<GeminiScreen> {
  late Future<List<dynamic>> _futureInfo;

  @override
  void initState() {
    super.initState();
    _futureInfo = ApiService.getGeminiInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Disease Information", style: TextStyle(color: Colors.white)),
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
        child: FutureBuilder<List<dynamic>>(
          future: _futureInfo,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green[700]),
                    SizedBox(height: 16),
                    Text(
                      "Loading disease information...",
                      style: TextStyle(color: Colors.green[800]),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _futureInfo = ApiService.getGeminiInfo();
                        });
                      },
                      icon: Icon(Icons.refresh),
                      label: Text("Try Again"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco, size: 48, color: Colors.green[700]),
                    SizedBox(height: 16),
                    Text(
                      "No disease information available yet",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Capture and analyze plant images to generate disease information",
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final entry = data[index] as Map<String, dynamic>;
                final diseaseName = entry["disease"] ?? "Unknown Disease";
                final confidence = entry["confidence"] ?? 0;
                final geminiInfo = entry["gemini_info"] ?? "No Gemini info available";
                final timestamp = entry["timestamp"] ?? "N/A";
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Disease Header
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.eco,
                                  color: Colors.green[800],
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  diseaseName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Confidence Indicator
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(confidence),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Confidence: ${(confidence * 100).toStringAsFixed(2)}%",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Disease Information
                          Text(
                            "Disease Information:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            geminiInfo,
                            style: TextStyle(
                              height: 1.4,
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Timestamp
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                timestamp,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }
}