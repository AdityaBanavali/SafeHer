import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import '../main.dart';

class EmergencyDashboard extends StatefulWidget {
  const EmergencyDashboard({super.key});
  @override
  State<EmergencyDashboard> createState() => EmergencyDashboardState();
}

class EmergencyDashboardState extends State<EmergencyDashboard> {
  final DatabaseReference _alertsRef = FirebaseDatabase.instance.ref('alerts');
  List<dynamic> _alertList = [];

  @override
  void initState() {
    super.initState();
    _alertsRef.onValue.listen((event) {
      if (event.snapshot.value == null) {
        if (mounted) setState(() => _alertList = []);
        return;
      }
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final list = data.entries.map((e) => {"key": e.key, ...e.value as Map}).toList();
      list.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
      if (mounted) setState(() => _alertList = list);
    }, onError: (error) {
      developer.log('Error listening to alerts: $error', name: 'safeher.emergency');
    });
  }

  void _launchMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    developer.log('Attempting to launch map with URI: $uri', name: 'safeher.emergency');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        developer.log('Could not launch $uri', name: 'safeher.emergency', error: 'canLaunchUrl returned false');
        _showErrorSnackbar('Could not open map.');
      }
    } catch (e) {
      developer.log('Error launching map: $e', name: 'safeher.emergency', error: e);
      _showErrorSnackbar('An error occurred while opening the map.');
    }
  }

  void _copyCoordinates(double lat, double lng) {
    Clipboard.setData(ClipboardData(text: '$lat, $lng')).then((_) {
      _showErrorSnackbar('Coordinates copied to clipboard');
    });
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety Monitor"),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: _alertList.isEmpty
          ? const Center(child: Text("No alerts yet."))
          : ListView.builder(
              itemCount: _alertList.length,
              itemBuilder: (context, i) {
                final a = _alertList[i];

                final latNum = a['lat'];
                final lngNum = a['lng'];

                final double? lat = (latNum is num) ? latNum.toDouble() : null;
                final double? lng = (lngNum is num) ? lngNum.toDouble() : null;
                
                final bool hasLocation = lat != null && lng != null && lat != 0.0 && lng != 0.0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(a['status'] == 'active' ? "Fall Detected!" : "Cleared", style: Theme.of(context).textTheme.titleLarge),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Time: ${a['time'] ?? 'N/A'}\nLocation: ${hasLocation ? '$lat, $lng' : 'Not available'}",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    isThreeLine: true,
                    onTap: hasLocation ? () => _launchMap(lat, lng) : null,
                    trailing: hasLocation
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.map, color: Colors.blue),
                                tooltip: 'Open in Map',
                                onPressed: () => _launchMap(lat, lng),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.grey),
                                tooltip: 'Copy Coordinates',
                                onPressed: () => _copyCoordinates(lat, lng),
                              ),
                            ],
                          )
                        : const Icon(Icons.location_off, color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}
