class BackupHistoryEntry {
  final String backupName;
  final DateTime date;
  final int size;
  final String location;
  final bool isCloud;
  final bool isEncrypted;

  BackupHistoryEntry({
    required this.backupName,
    required this.date,
    required this.size,
    required this.location,
    required this.isCloud,
    required this.isEncrypted,
  });

  Map<String, dynamic> toJson() => {
        'backupName': backupName,
        'date': date.toIso8601String(),
        'size': size,
        'location': location,
        'isCloud': isCloud,
        'isEncrypted': isEncrypted,
      };

  factory BackupHistoryEntry.fromJson(Map<String, dynamic> json) => BackupHistoryEntry(
        backupName: json['backupName'] as String,
        date: DateTime.parse(json['date'] as String),
        size: json['size'] as int,
        location: json['location'] as String,
        isCloud: json['isCloud'] as bool? ?? false,
        isEncrypted: json['isEncrypted'] as bool? ?? false,
      );
}
