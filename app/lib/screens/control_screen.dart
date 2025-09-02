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
      "pump_seconds": double.tryParse(_pumpController.text) ?? 0.0,
      "chemical": _chemicalController.text,
      "quantity_per_200L": "manual"
    };
    try {
      final res = await ApiService.sendOverride(payload);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Override set.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
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
        appBar: AppBar(title: Text("Manual Control")),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              SwitchListTile(
                title: Text("Spray (ON/OFF)"),
                value: _spray,
                onChanged: (v) => setState(() => _spray = v),
              ),
              TextField(
                controller: _servoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Servo index or angle"),
              ),
              TextField(
                controller: _pumpController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Pump seconds"),
              ),
              TextField(
                controller: _chemicalController,
                decoration: InputDecoration(labelText: "Chemical (label)"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _sendOverride,
                child: _loading ? CircularProgressIndicator(color: Colors.white) : Text("Send Override"),
              )
            ],
          ),
        ));
  }
}

