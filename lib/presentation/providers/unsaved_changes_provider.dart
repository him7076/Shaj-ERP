import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether a transaction/party form has pending unsaved changes.
final unsavedChangesProvider = StateProvider<bool>((ref) => false);
