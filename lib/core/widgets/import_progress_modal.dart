import 'package:flutter/material.dart';

class ImportProgressState {
  final int current;
  final int total;
  final String statusMessage;

  const ImportProgressState({
    required this.current,
    required this.total,
    required this.statusMessage,
  });
}

class ImportProgressModal extends StatefulWidget {
  final String title;
  final Stream<ImportProgressState> progressStream;

  const ImportProgressModal({
    Key? key,
    required this.title,
    required this.progressStream,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required String title,
    required Stream<ImportProgressState> progressStream,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ImportProgressModal(
        title: title,
        progressStream: progressStream,
      ),
    );
  }

  @override
  State<ImportProgressModal> createState() => _ImportProgressModalState();
}

class _ImportProgressModalState extends State<ImportProgressModal> {
  final DateTime _startTime = DateTime.now();

  String _calculateEstimatedTime(int current, int total) {
    if (current <= 0 || total <= 0 || current >= total) return '';
    final elapsedMs = DateTime.now().difference(_startTime).inMilliseconds;
    if (elapsedMs <= 0) return '';

    final msPerItem = elapsedMs / current;
    final remainingItems = total - current;
    final remainingMs = (msPerItem * remainingItems).round();

    final remainingSecs = (remainingMs / 1000).ceil();
    if (remainingSecs < 60) {
      return '~ $remainingSecs sec remaining';
    } else {
      final mins = remainingSecs ~/ 60;
      final secs = remainingSecs % 60;
      return '~ ${mins}m ${secs}s remaining';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<ImportProgressState>(
      stream: widget.progressStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const ImportProgressState(current: 0, total: 100, statusMessage: 'Preparing import...');

        final current = state.current;
        final total = state.total > 0 ? state.total : 1;
        final progressRatio = (current / total).clamp(0.0, 1.0);
        final percentage = (progressRatio * 100).toInt();

        final etaText = _calculateEstimatedTime(current, total);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cloud_upload_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Processing Excel records into local database...',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Percentage and Counter Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$percentage% Complete',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '$current / $total records',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 14),

                // Status Message and ETA Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (etaText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          etaText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
