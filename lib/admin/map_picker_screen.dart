import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchCtrl = TextEditingController();

  LatLng selected = LatLng(28.6139, 77.2090); // Default India
  bool searching = false;

  // 🔍 SEARCH LOCATION USING OPENSTREETMAP
  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => searching = true);

    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "User-Agent": "se_booking_app",
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);

        selected = LatLng(lat, lon);
        mapController.move(selected, 16);
      }
    }

    setState(() => searching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Center Location')),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search area / city / landmark',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searching
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () =>
                      searchLocation(searchCtrl.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: searchLocation,
            ),
          ),

          // 🗺 MAP
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: selected,
                initialZoom: 13,
                onTap: (_, point) {
                  setState(() => selected = point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.se_booking',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selected,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // ✅ CONFIRM BUTTON
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.check),
        label: const Text('Use This Location'),
        onPressed: () {
          Navigator.pop(context, {
            "lat": selected.latitude,
            "lng": selected.longitude,
          });
        },
      ),
    );
  }
}
