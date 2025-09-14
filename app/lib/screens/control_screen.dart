import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ControlScreen extends StatefulWidget {
  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final _servoController = TextEditingController(text: "0");
  final _pumpController = TextEditingController(text: "2.0");
  final _chemicalController = TextEditingController(text: "Manual");
  bool _spray = false;
  bool _loading = false;

  Future<void> _sendOverride() async {
    setState(() => _loading = true);
    final payload = {
      "spray": _spray,
      "servo_index": int.tryParse(_servoController.text) ?? 0,
      "spray_time": double.tryParse(_pumpController.text) ?? 0.0,
      "chemical": _chemicalController.text,
      "quantity_per_200L": "manual"
    };
    try {
      final res = await ApiService.sendOverride(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Override set successfully!"),
          backgroundColor: Colors.green,
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _servoController.dispose();
    _pumpController.dispose();
    _chemicalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manual Control"),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
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
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Manual Spray Control",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ),
              
              // Spray Control Card
              Card(
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
                        "Spray Control",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Spray System",
                            style: TextStyle(fontSize: 16),
                          ),
                          Transform.scale(
                            scale: 1.2,
                            child: Switch(
                              value: _spray,
                              onChanged: (v) => setState(() => _spray = v),
                              activeColor: Colors.green,
                              activeTrackColor: Colors.green[200],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _spray ? Icons.check_circle : Icons.cancel,
                            color: _spray ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 5),
                          Text(
                            _spray ? "System ACTIVE" : "System INACTIVE",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _spray ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Settings Card
              Card(
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
                        "Spray Settings",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Servo Input
                      _buildInputField(
                        controller: _servoController,
                        label: "Servo Index/Angle",
                        icon: Icons.settings,
                        type: TextInputType.number,
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Pump Input
                      _buildInputField(
                        controller: _pumpController,
                        label: "Spray Time (seconds)",
                        icon: Icons.timer,
                        type: TextInputType.numberWithOptions(decimal: true),
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Chemical Input
                      _buildInputField(
                        controller: _chemicalController,
                        label: "Chemical Name",
                        icon: Icons.eco,
                        type: TextInputType.text,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Action Button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendOverride,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _loading 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "APPLY SETTINGS",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Info Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "Note: These settings will override the automated system until the next cycle.",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType type,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green),
        ),
      ),
    );
  }
}