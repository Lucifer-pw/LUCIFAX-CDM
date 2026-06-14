import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/services/device_service.dart';
import 'package:lucifax_cdm/models/device_model.dart';

class MapTrackingScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const MapTrackingScreen({super.key, required this.deviceId});

  @override
  ConsumerState<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends ConsumerState<MapTrackingScreen> {
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    final deviceService = ref.watch(deviceServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lacak Lokasi Perangkat'),
      ),
      body: StreamBuilder<DeviceModel?>(
        stream: deviceService.streamDevice(widget.deviceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final device = snapshot.data;
          if (device == null || device.latitude == null || device.longitude == null) {
            return const Center(
              child: Text(
                'Lokasi perangkat belum tersedia.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final LatLng currentPos = LatLng(device.latitude!, device.longitude!);
          final markerId = MarkerId(device.id);
          final marker = Marker(
            markerId: markerId,
            position: currentPos,
            infoWindow: InfoWindow(
              title: device.deviceName,
              snippet: 'Baterai: ${device.battery}%',
            ),
          );

          _markers[markerId] = marker;

          // Animate camera to new position if map is ready
          _mapController?.animateCamera(CameraUpdate.newLatLng(currentPos));

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: currentPos,
                  zoom: 15.0,
                ),
                markers: Set<Marker>.of(_markers.values),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              
              // Top Overlay Info Card
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  color: AppColors.surface.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Koordinat: ${device.latitude}, ${device.longitude}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Terakhir Dilihat: ${device.lastSeen.hour.toString().padLeft(2, '0')}:${device.lastSeen.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
