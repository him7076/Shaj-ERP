class BackupMetadata {
  final String appVersion;
  final int databaseVersion;
  final DateTime backupDate;
  final bool hasPassword;
  final bool includeImages;
  final List<String> collectionsList;

  BackupMetadata({
    required this.appVersion,
    required this.databaseVersion,
    required this.backupDate,
    required this.hasPassword,
    required this.includeImages,
    required this.collectionsList,
  });

  Map<String, dynamic> toJson() => {
        'appVersion': appVersion,
        'databaseVersion': databaseVersion,
        'backupDate': backupDate.toIso8601String(),
        'hasPassword': hasPassword,
        'includeImages': includeImages,
        'collectionsList': collectionsList,
      };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
        appVersion: json['appVersion'] as String? ?? '1.0.0',
        databaseVersion: json['databaseVersion'] as int? ?? 1,
        backupDate: json['backupDate'] != null ? DateTime.parse(json['backupDate'] as String) : DateTime.now(),
        hasPassword: json['hasPassword'] as bool? ?? false,
        includeImages: json['includeImages'] as bool? ?? true,
        collectionsList: json['collectionsList'] != null ? List<String>.from(json['collectionsList']) : [],
      );
}
