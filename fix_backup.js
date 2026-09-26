const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, 'lib/core/services/snapshot_backup_service.dart');
let content = fs.readFileSync(file, 'utf8');

// 1. Modify createSnapshotBackup to only export activeFirmId
const backupRegex = /final firmsToExport = selectedFirmIds \?\? prefs\.getStringList\('firms_list'\) \?\? \[activeFirmId\];/;
const backupReplacement = `final firmsToExport = [activeFirmId]; // ONLY export active firm`;
content = content.replace(backupRegex, backupReplacement);

// 2. Modify restore preferences to map sourceFirmId keys to activeFirmId, and ignore global keys
const prefRestoreRegex = /for\s*\(\s*final\s*entry\s*in\s*prefMap\.entries\s*\)\s*\{[\s\S]*?final\s*key\s*=\s*entry\.key;[\s\S]*?final\s*val\s*=\s*entry\.value;[\s\S]*?if\s*\(val\s*is\s*bool\)\s*await\s*prefs\.setBool\(key,\s*val\);[\s\S]*?else\s*if\s*\(val\s*is\s*List\)\s*await\s*prefs\.setStringList\(key,\s*val\.map\(\(e\)\s*=>\s*e\.toString\(\)\)\.toList\(\)\);[\s\S]*?\}/;

const prefRestoreReplacement = `
        final sourceFirmId = (manifest['exportedFirms'] as List<dynamic>?)?.map((e) => e.toString()).toList().first ?? activeFirmId;
        
        for (final entry in prefMap.entries) {
          String key = entry.key;
          
          if (sourceFirmId != activeFirmId && key.endsWith(sourceFirmId)) {
             key = key.substring(0, key.length - sourceFirmId.length) + activeFirmId;
          }
          
          if (key == 'firms_list' || key == 'active_firm_id') continue;
          
          final val = entry.value;
          if (val is bool) await prefs.setBool(key, val);
          else if (val is int) await prefs.setInt(key, val);
          else if (val is double) await prefs.setDouble(key, val);
          else if (val is String) await prefs.setString(key, val);
          else if (val is List) await prefs.setStringList(key, val.map((e) => e.toString()).toList());
        }
`;
content = content.replace(prefRestoreRegex, prefRestoreReplacement);

// 3. Modify Web Restoration
const webRestoreRegex = /for\s*\(\s*final\s*firmId\s*in\s*exportedFirms\s*\)\s*\{[\s\S]*?ArchiveFile\?\s*jsonFile;[\s\S]*?for\s*\(\s*final\s*f\s*in\s*archive\s*\)\s*\{[\s\S]*?if\s*\(f\.name\s*==\s*'database_\$firmId\.json'\)\s*\{[\s\S]*?jsonFile\s*=\s*f;[\s\S]*?break;[\s\S]*?\}[\s\S]*?\}[\s\S]*?if\s*\(jsonFile\s*!=\s*null\)\s*\{[\s\S]*?final\s*jsonStr\s*=\s*utf8\.decode\(jsonFile\.content\s*as\s*List<int>\);[\s\S]*?final\s*collectionsData\s*=\s*jsonDecode\(jsonStr\)\s*as\s*Map<String,\s*dynamic>;[\s\S]*?final\s*isarInstance\s*=\s*dbService\.isar;[\s\S]*?if\s*\(isarInstance\s*is\s*WebMockIsar\)\s*\{[\s\S]*?isarInstance\.importCollectionsJson\(collectionsData\);[\s\S]*?await\s*isarInstance\.saveToPrefs\(prefs\);[\s\S]*?\}[\s\S]*?\}[\s\S]*?\}/;

const webRestoreReplacement = `
        final sourceFirmId = exportedFirms.isNotEmpty ? exportedFirms.first : activeFirmId;
        ArchiveFile? jsonFile;
        for (final f in archive) {
          if (f.name == 'database_$sourceFirmId.json') {
            jsonFile = f;
            break;
          }
        }

        if (jsonFile != null) {
          final jsonStr = utf8.decode(jsonFile.content as List<int>);
          final collectionsData = jsonDecode(jsonStr) as Map<String, dynamic>;
          final isarInstance = dbService.isar;
          if (isarInstance is WebMockIsar) {
            isarInstance.clearAllData();
            isarInstance.importCollectionsJson(collectionsData);
            await isarInstance.saveToPrefs(prefs);
          }
        }
`;
content = content.replace(webRestoreRegex, webRestoreReplacement);

// 4. Modify Native Restoration
const nativeRestoreRegex = /for\s*\(\s*final\s*firmId\s*in\s*exportedFirms\s*\)\s*\{[\s\S]*?ArchiveFile\?\s*binaryIsarFile;[\s\S]*?ArchiveFile\?\s*jsonFile;[\s\S]*?for\s*\(\s*final\s*f\s*in\s*archive\s*\)\s*\{[\s\S]*?if\s*\(f\.name\s*==\s*'database_\$firmId\.isar'\)\s*\{[\s\S]*?binaryIsarFile\s*=\s*f;[\s\S]*?\}\s*else\s*if\s*\(f\.name\s*==\s*'database_\$firmId\.json'\)\s*\{[\s\S]*?jsonFile\s*=\s*f;[\s\S]*?\}[\s\S]*?\}[\s\S]*?final\s*targetDbFile\s*=\s*File\('\$\{appDocsDir\.path\}\/\$firmId\.isar'\);[\s\S]*?if\s*\(await\s*targetDbFile\.exists\(\)\)\s*\{[\s\S]*?await\s*targetDbFile\.delete\(\);[\s\S]*?\}[\s\S]*?if\s*\(binaryIsarFile\s*!=\s*null\)\s*\{[\s\S]*?final\s*isarBytes\s*=\s*binaryIsarFile\.content\s*as\s*List<int>;[\s\S]*?await\s*targetDbFile\.writeAsBytes\(isarBytes,\s*flush:\s*true\);[\s\S]*?\}\s*else\s*if\s*\(jsonFile\s*!=\s*null\)\s*\{[\s\S]*?final\s*jsonStr\s*=\s*utf8\.decode\(jsonFile\.content\s*as\s*List<int>\);[\s\S]*?final\s*collectionsData\s*=\s*jsonDecode\(jsonStr\)\s*as\s*Map<String,\s*dynamic>;[\s\S]*?await\s*prefs\.setString\('active_firm_id',\s*firmId\);[\s\S]*?await\s*dbService\.init\(prefs\);[\s\S]*?await\s*dbService\.importCollectionsFromJson\(firmId,\s*collectionsData\);[\s\S]*?\}[\s\S]*?\}/;

const nativeRestoreReplacement = `
        final sourceFirmId = exportedFirms.isNotEmpty ? exportedFirms.first : activeFirmId;
        ArchiveFile? binaryIsarFile;
        ArchiveFile? jsonFile;

        for (final f in archive) {
          if (f.name == 'database_$sourceFirmId.isar') {
            binaryIsarFile = f;
          } else if (f.name == 'database_$sourceFirmId.json') {
            jsonFile = f;
          }
        }

        final targetDbFile = File('\${appDocsDir.path}/$activeFirmId.isar');
        if (await targetDbFile.exists()) {
          await targetDbFile.delete();
        }

        if (binaryIsarFile != null) {
          final isarBytes = binaryIsarFile.content as List<int>;
          await targetDbFile.writeAsBytes(isarBytes, flush: true);
        } else if (jsonFile != null) {
          final jsonStr = utf8.decode(jsonFile.content as List<int>);
          final collectionsData = jsonDecode(jsonStr) as Map<String, dynamic>;
          await dbService.init(prefs);
          await dbService.importCollectionsFromJson(activeFirmId, collectionsData);
        }
`;
content = content.replace(nativeRestoreRegex, nativeRestoreReplacement);

fs.writeFileSync(file, content, 'utf8');
console.log('Fixed backup/restore logic');
