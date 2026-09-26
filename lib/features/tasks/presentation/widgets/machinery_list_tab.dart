import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/tasks/presentation/providers/machinery_providers.dart';

class MachineryListTab extends ConsumerWidget {
  const MachineryListTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final machineryAsync = ref.watch(machineryListProvider);
    
    return machineryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (machineries) {
        if (machineries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings_applications_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No machinery found.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.push('/machinery/add'),
                  child: const Text('Add Machinery'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: machineries.length,
          itemBuilder: (context, index) {
            final machinery = machineries[index];
            return NeuCard(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.precision_manufacturing_rounded, color: theme.colorScheme.primary),
                ),
                title: Text(
                  machinery.machineName ?? 'Unnamed Machine',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (machinery.modelNumber != null && machinery.modelNumber!.isNotEmpty)
                      Text('Model: ${machinery.modelNumber}'),
                    const SizedBox(height: 8),
                    if (machinery.nextServiceDate != null)
                      Text(
                        'Next Service: ${DateFormat('dd MMM yyyy').format(machinery.nextServiceDate!)}',
                        style: TextStyle(
                          color: machinery.nextServiceDate!.isBefore(DateTime.now()) ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      const Text('No upcoming service scheduled', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                ),
                onTap: () => context.push('/machinery/edit/${machinery.id}'),
              ),
            );
          },
        );
      },
    );
  }
}
