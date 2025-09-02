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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Spray Logs"),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchLogs),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(child: Text("No logs yet"))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, idx) {
                    final log = _logs[idx] as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        title: Text("${log['disease'] ?? log['stage'] ?? 'Unknown'}"),
                        subtitle: Text("Chemical: ${log['chemical'] ?? 'N/A'}\nQuantity: ${log['quantity_per_200L'] ?? log['quantity'] ?? 'N/A'}"),
                        trailing: Text(log['timestamp'] ?? ''),
                        isThreeLine: true,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Log details"),
                              content: SingleChildScrollView(child: Text(log.toString())),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

