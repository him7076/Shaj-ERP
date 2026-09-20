import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/task_collection.dart';
import 'package:business_sahaj_erp/data/repositories/task_repository_impl.dart';
import 'package:business_sahaj_erp/domain/repositories/task_repository.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TaskRepositoryImpl(isar);
});

final taskListProvider = FutureProvider<List<Task>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  return await repository.getAll();
});

class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repository;
  final Ref _ref;

  TaskNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      await _repository.insert(task);
      _ref.invalidate(taskListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      await _repository.update(task);
      _ref.invalidate(taskListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      _ref.invalidate(taskListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final taskNotifierProvider = StateNotifierProvider<TaskNotifier, AsyncValue<void>>((ref) {
  return TaskNotifier(ref.watch(taskRepositoryProvider), ref);
});

final taskDetailProvider = FutureProvider.family<Task?, int>((ref, id) async {
  final repository = ref.watch(taskRepositoryProvider);
  return await repository.getById(id);
});
