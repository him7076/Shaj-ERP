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
  id: 8233573275319620190,
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
      id: 2134397340427724972,
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
    ),
    r'mappingType': IndexSchema(
      id: -2761947166389672708,
      name: r'mappingType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mappingType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'rawKey': IndexSchema(
      id: -4529732673282295727,
      name: r'rawKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'rawKey',
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

extension WhatsAppMappingByIndex on IsarCollection<WhatsAppMapping> {
  Future<WhatsAppMapping?> getByUuid(String? uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  WhatsAppMapping? getByUuidSync(String? uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String? uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String? uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<WhatsAppMapping?>> getAllByUuid(List<String?> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<WhatsAppMapping?> getAllByUuidSync(List<String?> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String?> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String?> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(WhatsAppMapping object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(WhatsAppMapping object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<WhatsAppMapping> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<WhatsAppMapping> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension WhatsAppMappingQueryWhereSort
    on QueryBuilder<WhatsAppMapping, WhatsAppMapping, QWhere> {
  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WhatsAppMappingQueryWhere
    on QueryBuilder<WhatsAppMapping, WhatsAppMapping, QWhereClause> {
  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [null],
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uuid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause> uuidEqualTo(
      String? uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      uuidNotEqualTo(String? uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      mappingTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mappingType',
        value: [null],
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      mappingTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mappingType',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      mappingTypeEqualTo(String? mappingType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mappingType',
        value: [mappingType],
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      mappingTypeNotEqualTo(String? mappingType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mappingType',
              lower: [],
              upper: [mappingType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mappingType',
              lower: [mappingType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mappingType',
              lower: [mappingType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mappingType',
              lower: [],
              upper: [mappingType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      rawKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'rawKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      rawKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'rawKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      rawKeyEqualTo(String? rawKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'rawKey',
        value: [rawKey],
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterWhereClause>
      rawKeyNotEqualTo(String? rawKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rawKey',
              lower: [],
              upper: [rawKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rawKey',
              lower: [rawKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rawKey',
              lower: [rawKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rawKey',
              lower: [],
              upper: [rawKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension WhatsAppMappingQueryFilter
    on QueryBuilder<WhatsAppMapping, WhatsAppMapping, QFilterCondition> {
  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      customRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customRate',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      customRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customRate',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      customRateEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      customRateGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      customRateLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      customRateBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mappingType',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mappingType',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mappingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mappingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mappingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mappingType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mappingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mappingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mappingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mappingType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mappingType',
        value: '',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      mappingTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mappingType',
        value: '',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerBundleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pcsPerBundle',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerBundleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pcsPerBundle',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerBundleEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pcsPerBundle',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerBundleGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pcsPerBundle',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerBundleLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pcsPerBundle',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerBundleBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pcsPerBundle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerCartonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pcsPerCarton',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerCartonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pcsPerCarton',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerCartonEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pcsPerCarton',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerCartonGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pcsPerCarton',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerCartonLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pcsPerCarton',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      pcsPerCartonBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pcsPerCarton',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rawKey',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rawKey',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rawKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rawKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rawKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rawKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rawKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rawKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rawKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawKey',
        value: '',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      rawKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rawKey',
        value: '',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetUuid',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetUuid',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'targetUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'targetUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'targetUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'targetUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      targetUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'targetUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      versionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterFilterCondition>
      versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WhatsAppMappingQueryObject
    on QueryBuilder<WhatsAppMapping, WhatsAppMapping, QFilterCondition> {}

extension WhatsAppMappingQueryLinks
    on QueryBuilder<WhatsAppMapping, WhatsAppMapping, QFilterCondition> {}

extension WhatsAppMappingQuerySortBy
    on QueryBuilder<WhatsAppMapping, WhatsAppMapping, QSortBy> {
  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByCustomRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customRate', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByCustomRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customRate', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByMappingType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mappingType', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByMappingTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mappingType', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByPcsPerBundle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pcsPerBundle', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByPcsPerBundleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pcsPerBundle', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByPcsPerCarton() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pcsPerCarton', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByPcsPerCartonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pcsPerCarton', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy> sortByRawKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawKey', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByRawKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawKey', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByTargetUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetUuid', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByTargetUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetUuid', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension WhatsAppMappingQuerySortThenBy
    on QueryBuilder<WhatsAppMapping, WhatsAppMapping, QSortThenBy> {
  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByCustomRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customRate', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByCustomRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customRate', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByMappingType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mappingType', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByMappingTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mappingType', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByPcsPerBundle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pcsPerBundle', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByPcsPerBundleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pcsPerBundle', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByPcsPerCarton() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pcsPerCarton', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByPcsPerCartonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pcsPerCarton', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy> thenByRawKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawKey', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByRawKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawKey', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByTargetUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetUuid', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByTargetUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetUuid', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension WhatsAppMappingQueryWhereDistinct
    on QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct> {
  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByCustomRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customRate');
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByMappingType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mappingType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByPcsPerBundle() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pcsPerBundle');
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByPcsPerCarton() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pcsPerCarton');
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct> distinctByRawKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByTargetUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WhatsAppMapping, WhatsAppMapping, QDistinct>
      distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension WhatsAppMappingQueryProperty
    on QueryBuilder<WhatsAppMapping, WhatsAppMapping, QQueryProperty> {
  QueryBuilder<WhatsAppMapping, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WhatsAppMapping, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<WhatsAppMapping, double?, QQueryOperations>
      customRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customRate');
    });
  }

  QueryBuilder<WhatsAppMapping, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<WhatsAppMapping, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<WhatsAppMapping, String?, QQueryOperations>
      mappingTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mappingType');
    });
  }

  QueryBuilder<WhatsAppMapping, double?, QQueryOperations>
      pcsPerBundleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pcsPerBundle');
    });
  }

  QueryBuilder<WhatsAppMapping, double?, QQueryOperations>
      pcsPerCartonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pcsPerCarton');
    });
  }

  QueryBuilder<WhatsAppMapping, String?, QQueryOperations> rawKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawKey');
    });
  }

  QueryBuilder<WhatsAppMapping, String?, QQueryOperations>
      targetUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetUuid');
    });
  }

  QueryBuilder<WhatsAppMapping, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<WhatsAppMapping, String?, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<WhatsAppMapping, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
