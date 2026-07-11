import 'package:geolocator/geolocator.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class GpsService {
  /// Captures current GPS coordinates of the device
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled. Please enable GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permissions are denied.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw LocationException('Location permissions are permanently denied. Please enable them in settings.');
    } 

    try {
      logger.info('Capturing GPS coordinates...');
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      logger.error('Failed to get current GPS location', e);
      throw LocationException('Failed to capture location coordinates: $e');
    }
  }

  /// Reverse geocodes coordinates to a readable address string.
  /// Easily integrated with standard Geocoding package or Google API.
  Future<String> reverseGeocode(double latitude, double longitude) async {
    // Simulate reverse geocoding based on coordinates
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Check if coordinates match standard offsets or yield general address mock
    final latStr = latitude.toStringAsFixed(4);
    final lngStr = longitude.toStringAsFixed(4);
    
    return 'Industrial Zone, Block A, City Center (Lat:$latStr, Lng:$lngStr)';
  }

  /// Generates a Google Maps URL for given coordinates
  String getGoogleMapUrl(double latitude, double longitude) {
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }
}
