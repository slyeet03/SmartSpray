import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _loading = true);
    try {
      final logs = await ApiService.getLogs();
      setState(() {
        _logs = logs.reversed.toList(); // show latest first
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading logs: ${e.toString()}"),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Spray History", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh), 
            onPressed: _fetchLogs,
            tooltip: "Refresh history",
          ),
        ],
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
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green[700]),
                    SizedBox(height: 16),
                    Text(
                      "Loading spray history...",
                      style: TextStyle(color: Colors.green[800]),
                    ),
                  ],
                ),
              )
            : _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.green[700]),
                        SizedBox(height: 16),
                        Text(
                          "No spray history yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Completed sprays will appear here",
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchLogs,
                    color: Colors.green[700],
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, idx) {
                        final log = _logs[idx] as Map<String, dynamic>;
                        final disease = _getFriendlyDiseaseName(log['disease'] ?? log['stage'] ?? 'Unknown');
                        final chemical = log['chemical'] ?? 'Not specified';
                        final quantity = log['quantity_per_200L'] ?? log['quantity'] ?? 'Not specified';
                        final timestamp = log['timestamp'] ?? '';
                        final sprayStatus = log['spray'] ?? false;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date and status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(timestamp),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: sprayStatus ? Colors.green[100] : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          sprayStatus ? "COMPLETED" : "NOT SPRAYED",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: sprayStatus ? Colors.green[800] : Colors.orange[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Disease detected
                                  Row(
                                    children: [
                                      Icon(Icons.visibility, size: 18, color: Colors.green[700]),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Detected: $disease",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Treatment applied
                                  Text(
                                    "Treatment Applied:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  
                                  Row(
                                    children: [
                                      Icon(Icons.eco, size: 16, color: Colors.green[700]),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          chemical,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 4),
                                  
                                  Row(
                                    children: [
                                      Icon(Icons.science, size: 16, color: Colors.green[700]),
                                      SizedBox(width: 6),
                                      Text(
                                        "Amount: $quantity per 200L water",
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 8),
                                  
                                  // Time
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(
                                        _formatTime(timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
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
                    ),
                  ),
      ),
    );
  }

  String _getFriendlyDiseaseName(String disease) {
    // Convert technical disease names to farmer-friendly terms
    final friendlyNames = {
      'healthy': 'Healthy Plant',
      'powdery_mildew': 'Powdery Mildew',
      'leaf_rust': 'Leaf Rust',
      'leaf_spot': 'Leaf Spot',
      'aphids': 'Aphid Infestation',
      'unknown': 'Unknown Issue',
    };
    
    return friendlyNames[disease.toLowerCase()] ?? disease;
  }

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) return "Date not available";
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final logDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (logDate == today) {
        return "Today";
      } else if (logDate == yesterday) {
        return "Yesterday";
      } else {
        return "${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}";
      }
    } catch (e) {
      return timestamp;
    }
  }
  
  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return "Time not available";
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final hour = dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour < 12 ? 'AM' : 'PM';
      
      return "Sprayed at ${hour == 0 ? 12 : hour}:$minute $period";
    } catch (e) {
      return "Time: $timestamp";
    }
  }
  
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}