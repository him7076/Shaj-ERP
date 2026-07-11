import 'dart:math';

class DistanceCalculator {
  /// Calculates the distance in meters between two sets of coordinates using the Haversine Formula
  static double calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's mean radius in meters
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Formats distance value to human-readable string
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters >= 1000) {
      final double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(2)} km';
    } else {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    }
  }
}
