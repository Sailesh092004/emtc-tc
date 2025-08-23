import 'package:location/location.dart';

class LocationFix {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  LocationFix({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    if (accuracy != null) 'accuracy': accuracy,
    'capturedAt': timestamp.toIso8601String(),
  };

  factory LocationFix.fromJson(Map<String, dynamic> json) => LocationFix(
    latitude: json['lat'] as double,
    longitude: json['lng'] as double,
    accuracy: json['accuracy'] as double?,
    timestamp: DateTime.parse(json['capturedAt'] as String),
  );
}

class LocationService {
  final Location _location = Location();

  Future<LocationFix?> getOnce() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      // Check location permission
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return null;
        }
      }

      // Get current location
      final locationData = await _location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        return LocationFix(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          accuracy: locationData.accuracy,
          timestamp: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
} 