abstract class BaseRepository<T> {
  /// Fetches a record by its local integer ID
  Future<T?> getById(int id);

  /// Fetches a record by its global UUID
  Future<T?> getByUuid(String uuid);

  /// Fetches all active (non-deleted) records
  Future<List<T>> getAll();

  /// Creates a new record in local storage
  Future<void> create(T entity, {bool isSyncDownload = false});

  /// Updates an existing record in local storage
  Future<void> update(T entity, {bool isSyncDownload = false});

  /// Hard/Soft delete record by local ID
  Future<void> delete(int id);

  /// Soft delete record by global UUID
  Future<void> softDelete(String uuid, {bool isSyncDownload = false});
}
