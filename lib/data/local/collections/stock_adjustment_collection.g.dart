// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_adjustment_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStockAdjustmentCollection on Isar {
  IsarCollection<StockAdjustment> get stockAdjustments => this.collection();
}

const StockAdjustmentSchema = CollectionSchema(
  name: r'StockAdjustment',
  id: 4892019482759102,
  properties: {
    r'adjustmentDate': PropertySchema(
      id: 0,
      name: r'adjustmentDate',
      type: IsarType.dateTime,
    ),
    r'adjustmentType': PropertySchema(
      id: 1,
      name: r'adjustmentType',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isDeleted': PropertySchema(
      id: 3,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 4,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'itemId': PropertySchema(
      id: 5,
      name: r'itemId',
      type: IsarType.long,
    ),
    r'itemName': PropertySchema(
      id: 6,
      name: r'itemName',
      type: IsarType.string,
    ),
    r'itemUuid': PropertySchema(
      id: 7,
      name: r'itemUuid',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 8,
      name: r'notes',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(
      id: 9,
      name: r'quantity',
      type: IsarType.double,
    ),
    r'reason': PropertySchema(
      id: 10,
      name: r'reason',
      type: IsarType.string,
    ),
    r'unit': PropertySchema(
      id: 11,
      name: r'unit',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 13,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 14,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _stockAdjustmentEstimateSize,
  serialize: _stockAdjustmentSerialize,
  deserialize: _stockAdjustmentDeserialize,
  deserializeProp: _stockAdjustmentDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 7394857291048291,
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
    r'itemUuid': IndexSchema(
      id: 8291048291739485,
      name: r'itemUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'itemUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _stockAdjustmentGetId,
  getLinks: _stockAdjustmentGetLinks,
  attach: _stockAdjustmentAttach,
  version: '3.1.0+1',
);

int _stockAdjustmentEstimateSize(
  StockAdjustment object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.adjustmentType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.itemName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.itemUuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.reason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.unit;
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

void _stockAdjustmentSerialize(
  StockAdjustment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.adjustmentDate);
  writer.writeString(offsets[1], object.adjustmentType);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeBool(offsets[3], object.isDeleted);
  writer.writeBool(offsets[4], object.isSynced);
  writer.writeLong(offsets[5], object.itemId);
  writer.writeString(offsets[6], object.itemName);
  writer.writeString(offsets[7], object.itemUuid);
  writer.writeString(offsets[8], object.notes);
  writer.writeDouble(offsets[9], object.quantity);
  writer.writeString(offsets[10], object.reason);
  writer.writeString(offsets[11], object.unit);
  writer.writeDateTime(offsets[12], object.updatedAt);
  writer.writeString(offsets[13], object.uuid);
  writer.writeLong(offsets[14], object.version);
}

StockAdjustment _stockAdjustmentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StockAdjustment();
  object.adjustmentDate = reader.readDateTimeOrNull(offsets[0]);
  object.adjustmentType = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.isDeleted = reader.readBool(offsets[3]);
  object.isSynced = reader.readBool(offsets[4]);
  object.itemId = reader.readLongOrNull(offsets[5]);
  object.itemName = reader.readStringOrNull(offsets[6]);
  object.itemUuid = reader.readStringOrNull(offsets[7]);
  object.notes = reader.readStringOrNull(offsets[8]);
  object.quantity = reader.readDoubleOrNull(offsets[9]);
  object.reason = reader.readStringOrNull(offsets[10]);
  object.unit = reader.readStringOrNull(offsets[11]);
  object.updatedAt = reader.readDateTime(offsets[12]);
  object.uuid = reader.readStringOrNull(offsets[13]);
  object.version = reader.readLong(offsets[14]);
  return object;
}

P _stockAdjustmentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _stockAdjustmentGetId(StockAdjustment object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _stockAdjustmentGetLinks(StockAdjustment object) {
  return [];
}

void _stockAdjustmentAttach(IsarCollection<dynamic> col, Id id, StockAdjustment object) {
  object.id = id;
}

extension StockAdjustmentByIndex on IsarCollection<StockAdjustment> {
  Future<StockAdjustment?> getByUuid(String? uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  StockAdjustment? getByUuidSync(String? uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }
}

extension StockAdjustmentQueryFilter on QueryBuilder<StockAdjustment, StockAdjustment, QFilterCondition> {
  QueryBuilder<StockAdjustment, StockAdjustment, QAfterFilterCondition> isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<StockAdjustment, StockAdjustment, QAfterFilterCondition> itemUuidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StockAdjustment, StockAdjustment, QAfterFilterCondition> itemNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StockAdjustment, StockAdjustment, QAfterFilterCondition> uuidEqualTo(
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
}

extension StockAdjustmentQuerySortBy on QueryBuilder<StockAdjustment, StockAdjustment, QSortBy> {
  QueryBuilder<StockAdjustment, StockAdjustment, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}
