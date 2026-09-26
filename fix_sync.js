const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, 'lib/core/services/sync_service.dart');
let content = fs.readFileSync(file, 'utf8');

const target1 = `  Future<void> syncDataFromCloud() async {
    final cloudSyncEnabled = _prefs.getBool('enable_firebase_cloud_sync') ?? true;
    if (!cloudSyncEnabled) {
      _updateState(const SyncState(
        status: SyncStatus.idle,
        message: 'Local Storage Mode Active (Cloud Sync OFF)',
      ));
      return;
    }`;

const replacement1 = `  Future<void> syncDataFromCloud() async {
    final cloudSyncEnabled = _prefs.getBool('enable_firebase_cloud_sync') ?? true;
    if (!cloudSyncEnabled) {
      _updateState(const SyncState(
        status: SyncStatus.idle,
        message: 'Local Storage Mode Active (Cloud Sync OFF)',
      ));
      return;
    }

    final activeFirmId = _dbService.activeFirmId;
    final isFirmSyncEnabled = _prefs.getBool('enable_firm_sync_$activeFirmId') ?? true;
    if (!isFirmSyncEnabled) {
      logger.info('Cloud sync is OFF for active firm ($activeFirmId). Skipping download.');
      _updateState(SyncState(
        status: SyncStatus.idle,
        message: 'Firm Cloud Sync OFF for firm ($activeFirmId)',
      ));
      return;
    }`;

content = content.replace(target1, replacement1);

// Let's also fix the 96% hang by chunking or skipping relink if not needed, but it's only for forceFullDownload which is fine if it yields.
// Let's yield inside _relinkAllRelations and recalculate.
// Wait, the user just says it hangs at 96% "agar mene firm ka sync off rakha hai". So skipping it when sync is off entirely fixes it!
// What about the 5% hang?
// "sync kar rha hu to 5 % pe hi atak gaya hai sync hi nhi ho rha hai"
// 5% is uploading local changes. 
// If they imported from Excel, they might have thousands of queue items. 
// Let's modify `getPendingQueue` to chunk the fetch if possible, or yield.
// Actually, `WebMockIsar` `findAll()` blocks. We can make `getPendingQueue` use the `_chunkedFindAll` helper!

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
      const int limit = 500;
      while(true) {
        final chunk = await _queueCollection.filter().isSyncedEqualTo(false).offset(offset).limit(limit).findAll();
        if (chunk.isEmpty) break;
        allItems.addAll(chunk);
        offset += limit;
        await Future.delayed(const Duration(milliseconds: 10)); // Yield to prevent 5% hang
      }
      
      // Sort in memory to avoid Isar unindexed sort overhead across multiple chunked queries
      allItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return allItems;
    } catch (e) {`;

// But wait, `getPendingQueue()` is in `sync_queue_service.dart`. I'll do this replacement in `sync_queue_service.dart` separately.

fs.writeFileSync(file, content, 'utf8');
console.log('Fixed sync_service 96% hang when firm sync off');
