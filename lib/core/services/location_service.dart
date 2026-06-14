import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucifax_cdm/core/services/firebase_service.dart';
import 'package:lucifax_cdm/models/location_model.dart';
import 'package:uuid/uuid.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirebaseFirestore _firestore = FirebaseService().firestore;
  StreamSubscription<Position>? _positionStreamSubscription;

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  void startTracking(String deviceId, {int intervalMinutes = 5}) async {
    await stopTracking();
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        const LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // track every 10 meters change
        );
        
        _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) async {
          await saveLocation(deviceId, position);
        });
        
        debugPrint('Realtime Location Tracking started for device $deviceId');
      }
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
    }
  }

  Future<void> stopTracking() async {
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
      debugPrint('Location Tracking stopped');
    }
  }

  Future<void> saveLocation(String deviceId, Position position) async {
    try {
      final String id = const Uuid().v4();
      final location = LocationModel(
        id: id,
        deviceId: deviceId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now(),
      );

      // Save to history subcollection
      await _firestore
          .collection('devices')
          .doc(deviceId)
          .collection('locations')
          .doc(id)
          .set(location.toJson());

      // Update current coordinates in device model
      await _firestore.collection('devices').doc(deviceId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  Stream<List<LocationModel>> streamLocationHistory(String deviceId) {
    return _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('locations')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LocationModel.fromJson(doc.data()))
          .toList();
    });
  }
}
