// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whatsapp_mapping_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWhatsAppMappingCollection on Isar {
  IsarCollection<WhatsAppMapping> get whatsAppMappings => this.collection();
}

const WhatsAppMappingSchema = CollectionSchema(
  name: r'WhatsAppMapping',
  id: 8841029471092834,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'customRate': PropertySchema(
      id: 1,
      name: r'customRate',
      type: IsarType.double,
    ),
    r'isDeleted': PropertySchema(
      id: 2,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 3,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'mappingType': PropertySchema(
      id: 4,
      name: r'mappingType',
      type: IsarType.string,
    ),
    r'pcsPerBundle': PropertySchema(
      id: 5,
      name: r'pcsPerBundle',
      type: IsarType.double,
    ),
    r'pcsPerCarton': PropertySchema(
      id: 6,
      name: r'pcsPerCarton',
      type: IsarType.double,
    ),
    r'rawKey': PropertySchema(
      id: 7,
      name: r'rawKey',
      type: IsarType.string,
    ),
    r'targetUuid': PropertySchema(
      id: 8,
      name: r'targetUuid',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 10,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 11,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _whatsAppMappingEstimateSize,
  serialize: _whatsAppMappingSerialize,
  deserialize: _whatsAppMappingDeserialize,
  deserializeProp: _whatsAppMappingDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 1337985571063474,
      name: r'uuid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _whatsAppMappingGetId,
  getLinks: _whatsAppMappingGetLinks,
  attach: _whatsAppMappingAttach,
  version: '3.1.0+1',
);

int _whatsAppMappingEstimateSize(
  WhatsAppMapping object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.mappingType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.rawKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.targetUuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.uuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _whatsAppMappingSerialize(
  WhatsAppMapping object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDouble(offsets[1], object.customRate);
  writer.writeBool(offsets[2], object.isDeleted);
  writer.writeBool(offsets[3], object.isSynced);
  writer.writeString(offsets[4], object.mappingType);
  writer.writeDouble(offsets[5], object.pcsPerBundle);
  writer.writeDouble(offsets[6], object.pcsPerCarton);
  writer.writeString(offsets[7], object.rawKey);
  writer.writeString(offsets[8], object.targetUuid);
  writer.writeDateTime(offsets[9], object.updatedAt);
  writer.writeString(offsets[10], object.uuid);
  writer.writeLong(offsets[11], object.version);
}

WhatsAppMapping _whatsAppMappingDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WhatsAppMapping();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.customRate = reader.readDoubleOrNull(offsets[1]);
  object.id = id;
  object.isDeleted = reader.readBool(offsets[2]);
  object.isSynced = reader.readBool(offsets[3]);
  object.mappingType = reader.readStringOrNull(offsets[4]);
  object.pcsPerBundle = reader.readDoubleOrNull(offsets[5]);
  object.pcsPerCarton = reader.readDoubleOrNull(offsets[6]);
  object.rawKey = reader.readStringOrNull(offsets[7]);
  object.targetUuid = reader.readStringOrNull(offsets[8]);
  object.updatedAt = reader.readDateTime(offsets[9]);
  object.uuid = reader.readStringOrNull(offsets[10]);
  object.version = reader.readLong(offsets[11]);
  return object;
}

P _whatsAppMappingDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _whatsAppMappingGetId(WhatsAppMapping object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _whatsAppMappingGetLinks(WhatsAppMapping object) {
  return [];
}

void _whatsAppMappingAttach(
    IsarCollection<dynamic> col, Id id, WhatsAppMapping object) {
  object.id = id;
}
