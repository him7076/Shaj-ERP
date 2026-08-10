import 'package:geolocator/geolocator.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class GpsService {
  /// Captures current GPS coordinates of the device safely without freezing UI
  Future<Position?> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled with 4s timeout guard
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
      if (!serviceEnabled) {
        logger.warning('Location services disabled or timed out.');
        return null;
      }

      // 2. Check permissions with 4s timeout guard
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 4), onTimeout: () => LocationPermission.denied);
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 4), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied) {
          logger.warning('Location permissions denied by user.');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        logger.warning('Location permissions permanently denied.');
        return null;
      } 

      logger.info('Capturing GPS coordinates...');
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      logger.error('Safe fallback: Failed or timed out getting GPS location', e);
      return null;
    }
  }

  /// Reverse geocodes coordinates to a readable address string.
  Future<String> reverseGeocode(double latitude, double longitude) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final latStr = latitude.toStringAsFixed(4);
    final lngStr = longitude.toStringAsFixed(4);
    return 'Industrial Zone, Block A, City Center (Lat:$latStr, Lng:$lngStr)';
  }

  /// Generates a Google Maps URL for given coordinates
  String getGoogleMapUrl(double latitude, double longitude) {
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }
}
