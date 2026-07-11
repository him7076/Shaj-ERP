import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Stream provider for raw connectivity changes (compatible with connectivity_plus 6.x)
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// A computed boolean provider to check if the app is online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStreamProvider);
  
  return connectivityAsync.maybeWhen(
    data: (results) {
      // If there's any active connection type that is not ConnectivityResult.none, the device is online
      return results.any((result) => result != ConnectivityResult.none);
    },
    // Default to true (assume online) or check initial state
    orElse: () => true, 
  );
});
