// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOrderCollection on Isar {
  IsarCollection<Order> get orders => this.collection();
}

const OrderSchema = CollectionSchema(
  name: r'Order',
  id: 1034948374866,
  properties: {
    r'cancellationReason': PropertySchema(
      id: 0,
      name: r'cancellationReason',
      type: IsarType.string,
    ),
    r'cancelledBy': PropertySchema(
      id: 1,
      name: r'cancelledBy',
      type: IsarType.string,
    ),
    r'cancelledDate': PropertySchema(
      id: 2,
      name: r'cancelledDate',
      type: IsarType.dateTime,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdBy': PropertySchema(
      id: 4,
      name: r'createdBy',
      type: IsarType.string,
    ),
    r'discountAmount': PropertySchema(
      id: 5,
      name: r'discountAmount',
      type: IsarType.double,
    ),
    r'discountPercent': PropertySchema(
      id: 6,
      name: r'discountPercent',
      type: IsarType.double,
    ),
    r'editTime': PropertySchema(
      id: 7,
      name: r'editTime',
      type: IsarType.dateTime,
    ),
    r'editedBy': PropertySchema(
      id: 8,
      name: r'editedBy',
      type: IsarType.string,
    ),
    r'grandTotal': PropertySchema(
      id: 9,
      name: r'grandTotal',
      type: IsarType.double,
    ),
    r'gstNumber': PropertySchema(
      id: 10,
      name: r'gstNumber',
      type: IsarType.string,
    ),
    r'internalNotes': PropertySchema(
      id: 11,
      name: r'internalNotes',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 12,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 13,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'latitude': PropertySchema(
      id: 14,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'locationAddress': PropertySchema(
      id: 15,
      name: r'locationAddress',
      type: IsarType.string,
    ),
    r'longitude': PropertySchema(
      id: 16,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'mobileNumber': PropertySchema(
      id: 17,
      name: r'mobileNumber',
      type: IsarType.string,
    ),
    r'orderDate': PropertySchema(
      id: 18,
      name: r'orderDate',
      type: IsarType.dateTime,
    ),
    r'orderNumber': PropertySchema(
      id: 19,
      name: r'orderNumber',
      type: IsarType.string,
    ),
    r'partyId': PropertySchema(
      id: 20,
      name: r'partyId',
      type: IsarType.long,
    ),
    r'partyName': PropertySchema(
      id: 21,
      name: r'partyName',
      type: IsarType.string,
    ),
    r'remarks': PropertySchema(
      id: 22,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'roundOff': PropertySchema(
      id: 23,
      name: r'roundOff',
      type: IsarType.double,
    ),
    r'status': PropertySchema(
      id: 24,
      name: r'status',
      type: IsarType.string,
    ),
    r'subtotal': PropertySchema(
      id: 25,
      name: r'subtotal',
      type: IsarType.double,
    ),
    r'totalGST': PropertySchema(
      id: 26,
      name: r'totalGST',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 27,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 28,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 29,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _orderEstimateSize,
  serialize: _orderSerialize,
  deserialize: _orderDeserialize,
  deserializeProp: _orderDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427,
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
    r'orderNumber': IndexSchema(
      id: 7506692016205,
      name: r'orderNumber',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'orderNumber',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'status': IndexSchema(
      id: -1077851706204,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'party': LinkSchema(
      id: 8095062533677,
      name: r'party',
      target: r'Party',
      single: true,
    ),
    r'orderItems': LinkSchema(
      id: -1325220897380,
      name: r'orderItems',
      target: r'OrderItem',
      single: false,
      linkName: r'order',
    )
  },
  embeddedSchemas: {},
  getId: _orderGetId,
  getLinks: _orderGetLinks,
  attach: _orderAttach,
  version: '3.1.0+1',
);

int _orderEstimateSize(
  Order object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cancellationReason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cancelledBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.createdBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.editedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.gstNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.internalNotes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.locationAddress;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mobileNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.orderNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.partyName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.remarks;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.status;
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

void _orderSerialize(
  Order object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cancellationReason);
  writer.writeString(offsets[1], object.cancelledBy);
  writer.writeDateTime(offsets[2], object.cancelledDate);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.createdBy);
  writer.writeDouble(offsets[5], object.discountAmount);
  writer.writeDouble(offsets[6], object.discountPercent);
  writer.writeDateTime(offsets[7], object.editTime);
  writer.writeString(offsets[8], object.editedBy);
  writer.writeDouble(offsets[9], object.grandTotal);
  writer.writeString(offsets[10], object.gstNumber);
  writer.writeString(offsets[11], object.internalNotes);
  writer.writeBool(offsets[12], object.isDeleted);
  writer.writeBool(offsets[13], object.isSynced);
  writer.writeDouble(offsets[14], object.latitude);
  writer.writeString(offsets[15], object.locationAddress);
  writer.writeDouble(offsets[16], object.longitude);
  writer.writeString(offsets[17], object.mobileNumber);
  writer.writeDateTime(offsets[18], object.orderDate);
  writer.writeString(offsets[19], object.orderNumber);
  writer.writeLong(offsets[20], object.partyId);
  writer.writeString(offsets[21], object.partyName);
  writer.writeString(offsets[22], object.remarks);
  writer.writeDouble(offsets[23], object.roundOff);
  writer.writeString(offsets[24], object.status);
  writer.writeDouble(offsets[25], object.subtotal);
  writer.writeDouble(offsets[26], object.totalGST);
  writer.writeDateTime(offsets[27], object.updatedAt);
  writer.writeString(offsets[28], object.uuid);
  writer.writeLong(offsets[29], object.version);
}

Order _orderDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Order();
  object.cancellationReason = reader.readStringOrNull(offsets[0]);
  object.cancelledBy = reader.readStringOrNull(offsets[1]);
  object.cancelledDate = reader.readDateTimeOrNull(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.createdBy = reader.readStringOrNull(offsets[4]);
  object.discountAmount = reader.readDoubleOrNull(offsets[5]);
  object.discountPercent = reader.readDoubleOrNull(offsets[6]);
  object.editTime = reader.readDateTimeOrNull(offsets[7]);
  object.editedBy = reader.readStringOrNull(offsets[8]);
  object.grandTotal = reader.readDoubleOrNull(offsets[9]);
  object.gstNumber = reader.readStringOrNull(offsets[10]);
  object.id = id;
  object.internalNotes = reader.readStringOrNull(offsets[11]);
  object.isDeleted = reader.readBool(offsets[12]);
  object.isSynced = reader.readBool(offsets[13]);
  object.latitude = reader.readDoubleOrNull(offsets[14]);
  object.locationAddress = reader.readStringOrNull(offsets[15]);
  object.longitude = reader.readDoubleOrNull(offsets[16]);
  object.mobileNumber = reader.readStringOrNull(offsets[17]);
  object.orderDate = reader.readDateTimeOrNull(offsets[18]);
  object.orderNumber = reader.readStringOrNull(offsets[19]);
  object.partyId = reader.readLongOrNull(offsets[20]);
  object.partyName = reader.readStringOrNull(offsets[21]);
  object.remarks = reader.readStringOrNull(offsets[22]);
  object.roundOff = reader.readDoubleOrNull(offsets[23]);
  object.status = reader.readStringOrNull(offsets[24]);
  object.subtotal = reader.readDoubleOrNull(offsets[25]);
  object.totalGST = reader.readDoubleOrNull(offsets[26]);
  object.updatedAt = reader.readDateTime(offsets[27]);
  object.uuid = reader.readStringOrNull(offsets[28]);
  object.version = reader.readLong(offsets[29]);
  return object;
}

P _orderDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readLongOrNull(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readDoubleOrNull(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readDoubleOrNull(offset)) as P;
    case 26:
      return (reader.readDoubleOrNull(offset)) as P;
    case 27:
      return (reader.readDateTime(offset)) as P;
    case 28:
      return (reader.readStringOrNull(offset)) as P;
    case 29:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _orderGetId(Order object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _orderGetLinks(Order object) {
  return [object.party, object.orderItems];
}

void _orderAttach(IsarCollection<dynamic> col, Id id, Order object) {
  object.id = id;
  object.party.attach(col, col.isar.collection<Party>(), r'party', id);
  object.orderItems
      .attach(col, col.isar.collection<OrderItem>(), r'orderItems', id);
}

extension OrderByIndex on IsarCollection<Order> {
  Future<Order?> getByUuid(String? uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Order? getByUuidSync(String? uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String? uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String? uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Order?>> getAllByUuid(List<String?> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Order?> getAllByUuidSync(List<String?> uuidValues) {
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

  Future<Id> putByUuid(Order object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Order object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Order> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Order> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }

  Future<Order?> getByOrderNumber(String? orderNumber) {
    return getByIndex(r'orderNumber', [orderNumber]);
  }

  Order? getByOrderNumberSync(String? orderNumber) {
    return getByIndexSync(r'orderNumber', [orderNumber]);
  }

  Future<bool> deleteByOrderNumber(String? orderNumber) {
    return deleteByIndex(r'orderNumber', [orderNumber]);
  }

  bool deleteByOrderNumberSync(String? orderNumber) {
    return deleteByIndexSync(r'orderNumber', [orderNumber]);
  }

  Future<List<Order?>> getAllByOrderNumber(List<String?> orderNumberValues) {
    final values = orderNumberValues.map((e) => [e]).toList();
    return getAllByIndex(r'orderNumber', values);
  }

  List<Order?> getAllByOrderNumberSync(List<String?> orderNumberValues) {
    final values = orderNumberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'orderNumber', values);
  }

  Future<int> deleteAllByOrderNumber(List<String?> orderNumberValues) {
    final values = orderNumberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'orderNumber', values);
  }

  int deleteAllByOrderNumberSync(List<String?> orderNumberValues) {
    final values = orderNumberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'orderNumber', values);
  }

  Future<Id> putByOrderNumber(Order object) {
    return putByIndex(r'orderNumber', object);
  }

  Id putByOrderNumberSync(Order object, {bool saveLinks = true}) {
    return putByIndexSync(r'orderNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOrderNumber(List<Order> objects) {
    return putAllByIndex(r'orderNumber', objects);
  }

  List<Id> putAllByOrderNumberSync(List<Order> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'orderNumber', objects, saveLinks: saveLinks);
  }
}

extension OrderQueryWhereSort on QueryBuilder<Order, Order, QWhere> {
  QueryBuilder<Order, Order, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OrderQueryWhere on QueryBuilder<Order, Order, QWhereClause> {
  QueryBuilder<Order, Order, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Order, Order, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> idBetween(
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

  QueryBuilder<Order, Order, QAfterWhereClause> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [null],
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uuid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> uuidEqualTo(String? uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> uuidNotEqualTo(String? uuid) {
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

  QueryBuilder<Order, Order, QAfterWhereClause> orderNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderNumber',
        value: [null],
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> orderNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderNumber',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> orderNumberEqualTo(
      String? orderNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderNumber',
        value: [orderNumber],
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> orderNumberNotEqualTo(
      String? orderNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderNumber',
              lower: [],
              upper: [orderNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderNumber',
              lower: [orderNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderNumber',
              lower: [orderNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderNumber',
              lower: [],
              upper: [orderNumber],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [null],
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> statusEqualTo(String? status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterWhereClause> statusNotEqualTo(
      String? status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OrderQueryFilter on QueryBuilder<Order, Order, QFilterCondition> {
  QueryBuilder<Order, Order, QAfterFilterCondition> cancellationReasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cancellationReason',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition>
      cancellationReasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cancellationReason',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancellationReasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancellationReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition>
      cancellationReasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cancellationReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancellationReasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cancellationReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancellationReasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cancellationReason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition>
      cancellationReasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cancellationReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancellationReasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cancellationReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancellationReasonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cancellationReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancellationReasonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cancellationReason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition>
      cancellationReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancellationReason',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition>
      cancellationReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cancellationReason',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cancelledBy',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cancelledBy',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancelledBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cancelledBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cancelledBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cancelledBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cancelledBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cancelledBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cancelledBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cancelledBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancelledBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cancelledBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cancelledDate',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cancelledDate',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancelledDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cancelledDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cancelledDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> cancelledDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cancelledDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'discountAmount',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'discountAmount',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discountAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discountAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discountAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discountAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountPercentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'discountPercent',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountPercentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'discountPercent',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountPercentEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discountPercent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountPercentGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discountPercent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountPercentLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discountPercent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> discountPercentBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discountPercent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'editTime',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'editTime',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'editTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'editTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'editTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'editTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'editedBy',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'editedBy',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'editedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'editedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'editedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'editedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'editedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'editedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'editedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'editedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'editedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> editedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'editedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> grandTotalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'grandTotal',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> grandTotalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'grandTotal',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> grandTotalEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'grandTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> grandTotalGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'grandTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> grandTotalLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'grandTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> grandTotalBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'grandTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gstNumber',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gstNumber',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gstNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gstNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gstNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gstNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'gstNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'gstNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'gstNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'gstNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gstNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> gstNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gstNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'internalNotes',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'internalNotes',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'internalNotes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'internalNotes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'internalNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> internalNotesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'internalNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> isDeletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> latitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latitude',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> latitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latitude',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> latitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> latitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> latitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> latitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'locationAddress',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'locationAddress',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locationAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'locationAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'locationAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'locationAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'locationAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'locationAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'locationAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'locationAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> locationAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locationAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition>
      locationAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'locationAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> longitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'longitude',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> longitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'longitude',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> longitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> longitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> longitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> longitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mobileNumber',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mobileNumber',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mobileNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mobileNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobileNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> mobileNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mobileNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderDate',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderDate',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderNumber',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderNumber',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'orderNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'orderNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partyId',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partyId',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partyId',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partyId',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partyId',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partyId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partyName',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partyName',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partyName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'partyName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partyName',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partyName',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> roundOffIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'roundOff',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> roundOffIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'roundOff',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> roundOffEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'roundOff',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> roundOffGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'roundOff',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> roundOffLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'roundOff',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> roundOffBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'roundOff',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> subtotalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subtotal',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> subtotalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subtotal',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> subtotalEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> subtotalGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> subtotalLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> subtotalBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subtotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> totalGSTIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalGST',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> totalGSTIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalGST',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> totalGSTEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalGST',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> totalGSTGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalGST',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> totalGSTLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalGST',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> totalGSTBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalGST',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidEqualTo(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidGreaterThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidLessThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidStartsWith(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidEndsWith(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> versionGreaterThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> versionLessThan(
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

  QueryBuilder<Order, Order, QAfterFilterCondition> versionBetween(
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

extension OrderQueryObject on QueryBuilder<Order, Order, QFilterCondition> {}

extension OrderQueryLinks on QueryBuilder<Order, Order, QFilterCondition> {
  QueryBuilder<Order, Order, QAfterFilterCondition> party(
      FilterQuery<Party> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'party');
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> partyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'party', 0, true, 0, true);
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderItems(
      FilterQuery<OrderItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'orderItems');
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderItemsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', length, true, length, true);
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderItemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', 0, true, 0, true);
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderItemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', 0, false, 999999, true);
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderItemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', 0, true, length, include);
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderItemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', length, include, 999999, true);
    });
  }

  QueryBuilder<Order, Order, QAfterFilterCondition> orderItemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'orderItems', lower, includeLower, upper, includeUpper);
    });
  }
}

extension OrderQuerySortBy on QueryBuilder<Order, Order, QSortBy> {
  QueryBuilder<Order, Order, QAfterSortBy> sortByCancellationReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancellationReason', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByCancellationReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancellationReason', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByCancelledBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledBy', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByCancelledByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledBy', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByCancelledDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledDate', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByCancelledDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledDate', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByDiscountPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByEditTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editTime', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByEditTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editTime', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByEditedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedBy', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByEditedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedBy', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByGrandTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByGstNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByGstNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByInternalNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'internalNotes', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByInternalNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'internalNotes', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByLocationAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationAddress', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByLocationAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationAddress', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByMobileNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileNumber', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByMobileNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileNumber', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByOrderDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderDate', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByOrderDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderDate', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByOrderNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNumber', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByOrderNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNumber', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByPartyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByPartyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByPartyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByPartyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByRoundOff() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByRoundOffDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByTotalGST() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByTotalGSTDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension OrderQuerySortThenBy on QueryBuilder<Order, Order, QSortThenBy> {
  QueryBuilder<Order, Order, QAfterSortBy> thenByCancellationReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancellationReason', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByCancellationReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancellationReason', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByCancelledBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledBy', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByCancelledByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledBy', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByCancelledDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledDate', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByCancelledDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledDate', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByDiscountPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByEditTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editTime', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByEditTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editTime', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByEditedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedBy', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByEditedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedBy', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByGrandTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByGstNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByGstNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByInternalNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'internalNotes', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByInternalNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'internalNotes', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByLocationAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationAddress', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByLocationAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationAddress', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByMobileNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileNumber', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByMobileNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileNumber', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByOrderDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderDate', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByOrderDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderDate', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByOrderNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNumber', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByOrderNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNumber', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByPartyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByPartyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByPartyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByPartyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByRoundOff() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByRoundOffDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByTotalGST() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByTotalGSTDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<Order, Order, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension OrderQueryWhereDistinct on QueryBuilder<Order, Order, QDistinct> {
  QueryBuilder<Order, Order, QDistinct> distinctByCancellationReason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cancellationReason',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByCancelledBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cancelledBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByCancelledDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cancelledDate');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByCreatedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountAmount');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountPercent');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByEditTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editTime');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByEditedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'grandTotal');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByGstNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gstNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByInternalNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'internalNotes',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByLocationAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locationAddress',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByMobileNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobileNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByOrderDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderDate');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByOrderNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByPartyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partyId');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByPartyName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByRoundOff() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roundOff');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtotal');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByTotalGST() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalGST');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Order, Order, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension OrderQueryProperty on QueryBuilder<Order, Order, QQueryProperty> {
  QueryBuilder<Order, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> cancellationReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cancellationReason');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> cancelledByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cancelledBy');
    });
  }

  QueryBuilder<Order, DateTime?, QQueryOperations> cancelledDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cancelledDate');
    });
  }

  QueryBuilder<Order, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<Order, double?, QQueryOperations> discountAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountAmount');
    });
  }

  QueryBuilder<Order, double?, QQueryOperations> discountPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountPercent');
    });
  }

  QueryBuilder<Order, DateTime?, QQueryOperations> editTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editTime');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> editedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editedBy');
    });
  }

  QueryBuilder<Order, double?, QQueryOperations> grandTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'grandTotal');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> gstNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gstNumber');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> internalNotesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'internalNotes');
    });
  }

  QueryBuilder<Order, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<Order, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<Order, double?, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> locationAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locationAddress');
    });
  }

  QueryBuilder<Order, double?, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> mobileNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobileNumber');
    });
  }

  QueryBuilder<Order, DateTime?, QQueryOperations> orderDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderDate');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> orderNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderNumber');
    });
  }

  QueryBuilder<Order, int?, QQueryOperations> partyIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partyId');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> partyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partyName');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<Order, double?, QQueryOperations> roundOffProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roundOff');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<Order, double?, QQueryOperations> subtotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtotal');
    });
  }

  QueryBuilder<Order, double?, QQueryOperations> totalGSTProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalGST');
    });
  }

  QueryBuilder<Order, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<Order, String?, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<Order, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
