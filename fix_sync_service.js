const fs = require('fs');
let content = fs.readFileSync('lib/core/services/sync_service.dart', 'utf-8');

// Replace the function signature
let oldSig = `    Future<void> processEnqueuing<T>(
        Future<List<T>> Function(int offset, int limit) queryFn,
        String entityType,
        String? Function(T) getUuid,
        int Function(T) getId) async {`;
let newSig = `    Future<void> processEnqueuing<T extends IsarModel>(
        Future<List<T>> Function(int offset, int limit) queryFn,
        String entityType) async {`;
content = content.replace(oldSig, newSig);

// Replace the queue mapping
let oldQueue = `        final queues = chunk.map((item) => SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = entityType
          ..entityId = getId(item)
          ..entityUuid = getUuid(item)`;
let newQueue = `        final queues = chunk.map((item) => SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = entityType
          ..entityId = item.id
          ..entityUuid = item.uuid`;
content = content.replace(oldQueue, newQueue);

// Remove the (e) => e.uuid, (e) => e.id
content = content.replace(/, \(e\) => e\.uuid, \(e\) => e\.id/g, '');

fs.writeFileSync('lib/core/services/sync_service.dart', content);
console.log('Replaced successfully');
