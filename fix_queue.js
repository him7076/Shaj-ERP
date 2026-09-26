const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, 'lib/core/services/sync_queue_service.dart');
let content = fs.readFileSync(file, 'utf8');

const target2 = `  Future<List<SyncQueue>> getPendingQueue() async {
    try {
      final allItems = await _queueCollection.filter().isSyncedEqualTo(false).findAll();
      // Sort in memory to avoid Isar unindexed sort overhead across multiple chunked queries
      allItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return allItems;
    } catch (e) {`;

const replacement2 = `  Future<List<SyncQueue>> getPendingQueue() async {
    try {
      // Chunked fetch to prevent web freezing on large queues
      final List<SyncQueue> allItems = [];
      int offset = 0;
      const int limit = 1000;
      while(true) {
        final chunk = await _queueCollection.filter().isSyncedEqualTo(false).offset(offset).limit(limit).findAll();
        if (chunk.isEmpty) break;
        allItems.addAll(chunk);
        offset += limit;
        await Future.delayed(const Duration(milliseconds: 20)); // Yield to prevent 5% hang
      }
      
      // Sort in memory to avoid Isar unindexed sort overhead across multiple chunked queries
      allItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return allItems;
    } catch (e) {`;

content = content.replace(target2, replacement2);

fs.writeFileSync(file, content, 'utf8');
console.log('Fixed sync_queue_service 5% hang');
