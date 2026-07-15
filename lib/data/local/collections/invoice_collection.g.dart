// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetInvoiceCollection on Isar {
  IsarCollection<Invoice> get invoices => this.collection();
}

const InvoiceSchema = CollectionSchema(
  name: r'Invoice',
  id: -3413994360176,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'cancellationReason': PropertySchema(
      id: 1,
      name: r'cancellationReason',
      type: IsarType.string,
    ),
    r'cancelledBy': PropertySchema(
      id: 2,
      name: r'cancelledBy',
      type: IsarType.string,
    ),
    r'cancelledDate': PropertySchema(
      id: 3,
      name: r'cancelledDate',
      type: IsarType.dateTime,
    ),
    r'cgstAmount': PropertySchema(
      id: 4,
      name: r'cgstAmount',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 5,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdBy': PropertySchema(
      id: 6,
      name: r'createdBy',
      type: IsarType.string,
    ),
    r'discountAmount': PropertySchema(
      id: 7,
      name: r'discountAmount',
      type: IsarType.double,
    ),
    r'dueDate': PropertySchema(
      id: 8,
      name: r'dueDate',
      type: IsarType.dateTime,
    ),
    r'editTime': PropertySchema(
      id: 9,
      name: r'editTime',
      type: IsarType.dateTime,
    ),
    r'editedBy': PropertySchema(
      id: 10,
      name: r'editedBy',
      type: IsarType.string,
    ),
    r'grandTotal': PropertySchema(
      id: 11,
      name: r'grandTotal',
      type: IsarType.double,
    ),
    r'gstNumber': PropertySchema(
      id: 12,
      name: r'gstNumber',
      type: IsarType.string,
    ),
    r'igstAmount': PropertySchema(
      id: 13,
      name: r'igstAmount',
      type: IsarType.double,
    ),
    r'invoiceDate': PropertySchema(
      id: 14,
      name: r'invoiceDate',
      type: IsarType.dateTime,
    ),
    r'invoiceNumber': PropertySchema(
      id: 15,
      name: r'invoiceNumber',
      type: IsarType.string,
    ),
    r'invoiceStatus': PropertySchema(
      id: 16,
      name: r'invoiceStatus',
      type: IsarType.string,
    ),
    r'invoiceType': PropertySchema(
      id: 17,
      name: r'invoiceType',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 18,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 19,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'paidAmount': PropertySchema(
      id: 20,
      name: r'paidAmount',
      type: IsarType.double,
    ),
    r'partyId': PropertySchema(
      id: 21,
      name: r'partyId',
      type: IsarType.long,
    ),
    r'partyName': PropertySchema(
      id: 22,
      name: r'partyName',
      type: IsarType.string,
    ),
    r'paymentStatus': PropertySchema(
      id: 23,
      name: r'paymentStatus',
      type: IsarType.string,
    ),
    r'pendingAmount': PropertySchema(
      id: 24,
      name: r'pendingAmount',
      type: IsarType.double,
    ),
    r'remarks': PropertySchema(
      id: 25,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'roundOff': PropertySchema(
      id: 26,
      name: r'roundOff',
      type: IsarType.double,
    ),
    r'sgstAmount': PropertySchema(
      id: 27,
      name: r'sgstAmount',
      type: IsarType.double,
    ),
    r'sourceOrderId': PropertySchema(
      id: 28,
      name: r'sourceOrderId',
      type: IsarType.long,
    ),
    r'sourceOrderNumber': PropertySchema(
      id: 29,
      name: r'sourceOrderNumber',
      type: IsarType.string,
    ),
    r'subtotal': PropertySchema(
      id: 30,
      name: r'subtotal',
      type: IsarType.double,
    ),
    r'taxableAmount': PropertySchema(
      id: 31,
      name: r'taxableAmount',
      type: IsarType.double,
    ),
    r'termsAndConditions': PropertySchema(
      id: 32,
      name: r'termsAndConditions',
      type: IsarType.string,
    ),
    r'totalGST': PropertySchema(
      id: 33,
      name: r'totalGST',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 34,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 35,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 36,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _invoiceEstimateSize,
  serialize: _invoiceSerialize,
  deserialize: _invoiceDeserialize,
  deserializeProp: _invoiceDeserializeProp,
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
    r'invoiceNumber': IndexSchema(
      id: -6231821761165,
      name: r'invoiceNumber',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'invoiceNumber',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'invoiceType': IndexSchema(
      id: 3218045535277,
      name: r'invoiceType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'invoiceType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'invoiceStatus': IndexSchema(
      id: -1978661240981,
      name: r'invoiceStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'invoiceStatus',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'paymentStatus': IndexSchema(
      id: 7011973130100,
      name: r'paymentStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'paymentStatus',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'party': LinkSchema(
      id: -9135347666935,
      name: r'party',
      target: r'Party',
      single: true,
    ),
    r'order': LinkSchema(
      id: 5716072027851,
      name: r'order',
      target: r'Order',
      single: true,
    ),
    r'invoiceItems': LinkSchema(
      id: 3389505747480,
      name: r'invoiceItems',
      target: r'InvoiceItem',
      single: false,
      linkName: r'invoice',
    )
  },
  embeddedSchemas: {},
  getId: _invoiceGetId,
  getLinks: _invoiceGetLinks,
  attach: _invoiceAttach,
  version: '3.1.0+1',
);

int _invoiceEstimateSize(
  Invoice object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.address;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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
    final value = object.invoiceNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.invoiceStatus;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.invoiceType;
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
    final value = object.paymentStatus;
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
    final value = object.sourceOrderNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.termsAndConditions;
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

void _invoiceSerialize(
  Invoice object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeString(offsets[1], object.cancellationReason);
  writer.writeString(offsets[2], object.cancelledBy);
  writer.writeDateTime(offsets[3], object.cancelledDate);
  writer.writeDouble(offsets[4], object.cgstAmount);
  writer.writeDateTime(offsets[5], object.createdAt);
  writer.writeString(offsets[6], object.createdBy);
  writer.writeDouble(offsets[7], object.discountAmount);
  writer.writeDateTime(offsets[8], object.dueDate);
  writer.writeDateTime(offsets[9], object.editTime);
  writer.writeString(offsets[10], object.editedBy);
  writer.writeDouble(offsets[11], object.grandTotal);
  writer.writeString(offsets[12], object.gstNumber);
  writer.writeDouble(offsets[13], object.igstAmount);
  writer.writeDateTime(offsets[14], object.invoiceDate);
  writer.writeString(offsets[15], object.invoiceNumber);
  writer.writeString(offsets[16], object.invoiceStatus);
  writer.writeString(offsets[17], object.invoiceType);
  writer.writeBool(offsets[18], object.isDeleted);
  writer.writeBool(offsets[19], object.isSynced);
  writer.writeDouble(offsets[20], object.paidAmount);
  writer.writeLong(offsets[21], object.partyId);
  writer.writeString(offsets[22], object.partyName);
  writer.writeString(offsets[23], object.paymentStatus);
  writer.writeDouble(offsets[24], object.pendingAmount);
  writer.writeString(offsets[25], object.remarks);
  writer.writeDouble(offsets[26], object.roundOff);
  writer.writeDouble(offsets[27], object.sgstAmount);
  writer.writeLong(offsets[28], object.sourceOrderId);
  writer.writeString(offsets[29], object.sourceOrderNumber);
  writer.writeDouble(offsets[30], object.subtotal);
  writer.writeDouble(offsets[31], object.taxableAmount);
  writer.writeString(offsets[32], object.termsAndConditions);
  writer.writeDouble(offsets[33], object.totalGST);
  writer.writeDateTime(offsets[34], object.updatedAt);
  writer.writeString(offsets[35], object.uuid);
  writer.writeLong(offsets[36], object.version);
}

Invoice _invoiceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Invoice();
  object.address = reader.readStringOrNull(offsets[0]);
  object.cancellationReason = reader.readStringOrNull(offsets[1]);
  object.cancelledBy = reader.readStringOrNull(offsets[2]);
  object.cancelledDate = reader.readDateTimeOrNull(offsets[3]);
  object.cgstAmount = reader.readDoubleOrNull(offsets[4]);
  object.createdAt = reader.readDateTime(offsets[5]);
  object.createdBy = reader.readStringOrNull(offsets[6]);
  object.discountAmount = reader.readDoubleOrNull(offsets[7]);
  object.dueDate = reader.readDateTimeOrNull(offsets[8]);
  object.editTime = reader.readDateTimeOrNull(offsets[9]);
  object.editedBy = reader.readStringOrNull(offsets[10]);
  object.grandTotal = reader.readDoubleOrNull(offsets[11]);
  object.gstNumber = reader.readStringOrNull(offsets[12]);
  object.id = id;
  object.igstAmount = reader.readDoubleOrNull(offsets[13]);
  object.invoiceDate = reader.readDateTimeOrNull(offsets[14]);
  object.invoiceNumber = reader.readStringOrNull(offsets[15]);
  object.invoiceStatus = reader.readStringOrNull(offsets[16]);
  object.invoiceType = reader.readStringOrNull(offsets[17]);
  object.isDeleted = reader.readBool(offsets[18]);
  object.isSynced = reader.readBool(offsets[19]);
  object.paidAmount = reader.readDoubleOrNull(offsets[20]);
  object.partyId = reader.readLongOrNull(offsets[21]);
  object.partyName = reader.readStringOrNull(offsets[22]);
  object.paymentStatus = reader.readStringOrNull(offsets[23]);
  object.pendingAmount = reader.readDoubleOrNull(offsets[24]);
  object.remarks = reader.readStringOrNull(offsets[25]);
  object.roundOff = reader.readDoubleOrNull(offsets[26]);
  object.sgstAmount = reader.readDoubleOrNull(offsets[27]);
  object.sourceOrderId = reader.readLongOrNull(offsets[28]);
  object.sourceOrderNumber = reader.readStringOrNull(offsets[29]);
  object.subtotal = reader.readDoubleOrNull(offsets[30]);
  object.taxableAmount = reader.readDoubleOrNull(offsets[31]);
  object.termsAndConditions = reader.readStringOrNull(offsets[32]);
  object.totalGST = reader.readDoubleOrNull(offsets[33]);
  object.updatedAt = reader.readDateTime(offsets[34]);
  object.uuid = reader.readStringOrNull(offsets[35]);
  object.version = reader.readLong(offsets[36]);
  return object;
}

P _invoiceDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readBool(offset)) as P;
    case 19:
      return (reader.readBool(offset)) as P;
    case 20:
      return (reader.readDoubleOrNull(offset)) as P;
    case 21:
      return (reader.readLongOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readDoubleOrNull(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readDoubleOrNull(offset)) as P;
    case 27:
      return (reader.readDoubleOrNull(offset)) as P;
    case 28:
      return (reader.readLongOrNull(offset)) as P;
    case 29:
      return (reader.readStringOrNull(offset)) as P;
    case 30:
      return (reader.readDoubleOrNull(offset)) as P;
    case 31:
      return (reader.readDoubleOrNull(offset)) as P;
    case 32:
      return (reader.readStringOrNull(offset)) as P;
    case 33:
      return (reader.readDoubleOrNull(offset)) as P;
    case 34:
      return (reader.readDateTime(offset)) as P;
    case 35:
      return (reader.readStringOrNull(offset)) as P;
    case 36:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _invoiceGetId(Invoice object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _invoiceGetLinks(Invoice object) {
  return [object.party, object.order, object.invoiceItems];
}

void _invoiceAttach(IsarCollection<dynamic> col, Id id, Invoice object) {
  object.id = id;
  object.party.attach(col, col.isar.collection<Party>(), r'party', id);
  object.order.attach(col, col.isar.collection<Order>(), r'order', id);
  object.invoiceItems
      .attach(col, col.isar.collection<InvoiceItem>(), r'invoiceItems', id);
}

extension InvoiceByIndex on IsarCollection<Invoice> {
  Future<Invoice?> getByUuid(String? uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Invoice? getByUuidSync(String? uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String? uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String? uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Invoice?>> getAllByUuid(List<String?> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Invoice?> getAllByUuidSync(List<String?> uuidValues) {
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

  Future<Id> putByUuid(Invoice object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Invoice object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Invoice> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Invoice> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }

  Future<Invoice?> getByInvoiceNumber(String? invoiceNumber) {
    return getByIndex(r'invoiceNumber', [invoiceNumber]);
  }

  Invoice? getByInvoiceNumberSync(String? invoiceNumber) {
    return getByIndexSync(r'invoiceNumber', [invoiceNumber]);
  }

  Future<bool> deleteByInvoiceNumber(String? invoiceNumber) {
    return deleteByIndex(r'invoiceNumber', [invoiceNumber]);
  }

  bool deleteByInvoiceNumberSync(String? invoiceNumber) {
    return deleteByIndexSync(r'invoiceNumber', [invoiceNumber]);
  }

  Future<List<Invoice?>> getAllByInvoiceNumber(
      List<String?> invoiceNumberValues) {
    final values = invoiceNumberValues.map((e) => [e]).toList();
    return getAllByIndex(r'invoiceNumber', values);
  }

  List<Invoice?> getAllByInvoiceNumberSync(List<String?> invoiceNumberValues) {
    final values = invoiceNumberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'invoiceNumber', values);
  }

  Future<int> deleteAllByInvoiceNumber(List<String?> invoiceNumberValues) {
    final values = invoiceNumberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'invoiceNumber', values);
  }

  int deleteAllByInvoiceNumberSync(List<String?> invoiceNumberValues) {
    final values = invoiceNumberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'invoiceNumber', values);
  }

  Future<Id> putByInvoiceNumber(Invoice object) {
    return putByIndex(r'invoiceNumber', object);
  }

  Id putByInvoiceNumberSync(Invoice object, {bool saveLinks = true}) {
    return putByIndexSync(r'invoiceNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByInvoiceNumber(List<Invoice> objects) {
    return putAllByIndex(r'invoiceNumber', objects);
  }

  List<Id> putAllByInvoiceNumberSync(List<Invoice> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'invoiceNumber', objects, saveLinks: saveLinks);
  }
}

extension InvoiceQueryWhereSort on QueryBuilder<Invoice, Invoice, QWhere> {
  QueryBuilder<Invoice, Invoice, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension InvoiceQueryWhere on QueryBuilder<Invoice, Invoice, QWhereClause> {
  QueryBuilder<Invoice, Invoice, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> idBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [null],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uuid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> uuidEqualTo(String? uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> uuidNotEqualTo(
      String? uuid) {
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

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'invoiceNumber',
        value: [null],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'invoiceNumber',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceNumberEqualTo(
      String? invoiceNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'invoiceNumber',
        value: [invoiceNumber],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceNumberNotEqualTo(
      String? invoiceNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceNumber',
              lower: [],
              upper: [invoiceNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceNumber',
              lower: [invoiceNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceNumber',
              lower: [invoiceNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceNumber',
              lower: [],
              upper: [invoiceNumber],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'invoiceType',
        value: [null],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'invoiceType',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceTypeEqualTo(
      String? invoiceType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'invoiceType',
        value: [invoiceType],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceTypeNotEqualTo(
      String? invoiceType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceType',
              lower: [],
              upper: [invoiceType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceType',
              lower: [invoiceType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceType',
              lower: [invoiceType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceType',
              lower: [],
              upper: [invoiceType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'invoiceStatus',
        value: [null],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'invoiceStatus',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceStatusEqualTo(
      String? invoiceStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'invoiceStatus',
        value: [invoiceStatus],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> invoiceStatusNotEqualTo(
      String? invoiceStatus) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceStatus',
              lower: [],
              upper: [invoiceStatus],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceStatus',
              lower: [invoiceStatus],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceStatus',
              lower: [invoiceStatus],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceStatus',
              lower: [],
              upper: [invoiceStatus],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> paymentStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'paymentStatus',
        value: [null],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> paymentStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'paymentStatus',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> paymentStatusEqualTo(
      String? paymentStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'paymentStatus',
        value: [paymentStatus],
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterWhereClause> paymentStatusNotEqualTo(
      String? paymentStatus) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentStatus',
              lower: [],
              upper: [paymentStatus],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentStatus',
              lower: [paymentStatus],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentStatus',
              lower: [paymentStatus],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentStatus',
              lower: [],
              upper: [paymentStatus],
              includeUpper: false,
            ));
      }
    });
  }
}

extension InvoiceQueryFilter
    on QueryBuilder<Invoice, Invoice, QFilterCondition> {
  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'address',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cancellationReason',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cancellationReason',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonEndsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cancellationReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cancellationReason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancellationReason',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancellationReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cancellationReason',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cancelledBy',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cancelledBy',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByStartsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByEndsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByContains(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByMatches(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancelledBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancelledByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cancelledBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cancelledDate',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancelledDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cancelledDate',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancelledDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      cancelledDateGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledDateLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cancelledDateBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cgstAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cgstAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cgstAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cgstAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cgstAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cgstAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cgstAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cgstAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cgstAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cgstAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> cgstAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cgstAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByStartsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByEndsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByContains(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByMatches(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> discountAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'discountAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      discountAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'discountAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> discountAmountEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      discountAmountGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> discountAmountLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> discountAmountBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> dueDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dueDate',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> dueDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dueDate',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> dueDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> dueDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> dueDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> dueDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dueDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'editTime',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'editTime',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'editTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editTimeGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editTimeLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editTimeBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'editedBy',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'editedBy',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByStartsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByEndsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByContains(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByMatches(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'editedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> editedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'editedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> grandTotalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'grandTotal',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> grandTotalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'grandTotal',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> grandTotalEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> grandTotalGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> grandTotalLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> grandTotalBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gstNumber',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gstNumber',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberStartsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberEndsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberContains(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberMatches(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gstNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> gstNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gstNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> igstAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'igstAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> igstAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'igstAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> igstAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'igstAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> igstAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'igstAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> igstAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'igstAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> igstAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'igstAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'invoiceDate',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'invoiceDate',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoiceDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoiceDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoiceDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'invoiceNumber',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'invoiceNumber',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoiceNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceNumberContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceNumberMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoiceNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'invoiceStatus',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'invoiceStatus',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceStatusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoiceStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoiceStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoiceStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invoiceStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invoiceStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceStatusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoiceStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceStatusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoiceStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoiceStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'invoiceType',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'invoiceType',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoiceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoiceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoiceType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invoiceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invoiceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoiceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoiceType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceType',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoiceType',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> isDeletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paidAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paidAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paidAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paidAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paidAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paidAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paidAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paidAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paidAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paidAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paidAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paidAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partyId',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partyId',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partyId',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyIdGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyIdLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyIdBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partyName',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partyName',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameStartsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameEndsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameContains(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameMatches(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partyName',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partyName',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paymentStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentStatus',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      paymentStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentStatus',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paymentStatusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      paymentStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paymentStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paymentStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paymentStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paymentStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paymentStatusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paymentStatusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> paymentStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      paymentStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> pendingAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pendingAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      pendingAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pendingAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> pendingAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      pendingAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pendingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> pendingAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pendingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> pendingAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pendingAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksStartsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksEndsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksContains(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksMatches(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> roundOffIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'roundOff',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> roundOffIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'roundOff',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> roundOffEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> roundOffGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> roundOffLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> roundOffBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sgstAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sgstAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sgstAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sgstAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sgstAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sgstAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sgstAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sgstAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sgstAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sgstAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sgstAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sgstAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sourceOrderIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceOrderId',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceOrderId',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sourceOrderIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceOrderId',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceOrderId',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sourceOrderIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceOrderId',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> sourceOrderIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceOrderId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceOrderNumber',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceOrderNumber',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceOrderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceOrderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceOrderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceOrderNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceOrderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceOrderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceOrderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceOrderNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceOrderNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      sourceOrderNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceOrderNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> subtotalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subtotal',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> subtotalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subtotal',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> subtotalEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> subtotalGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> subtotalLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> subtotalBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> taxableAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'taxableAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      taxableAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'taxableAmount',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> taxableAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taxableAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      taxableAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taxableAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> taxableAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taxableAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> taxableAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taxableAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'termsAndConditions',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'termsAndConditions',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'termsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'termsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'termsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'termsAndConditions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'termsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'termsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'termsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'termsAndConditions',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'termsAndConditions',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      termsAndConditionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'termsAndConditions',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> totalGSTIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalGST',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> totalGSTIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalGST',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> totalGSTEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> totalGSTGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> totalGSTLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> totalGSTBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidEqualTo(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidStartsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidEndsWith(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> versionEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> versionGreaterThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> versionLessThan(
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

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> versionBetween(
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

extension InvoiceQueryObject
    on QueryBuilder<Invoice, Invoice, QFilterCondition> {}

extension InvoiceQueryLinks
    on QueryBuilder<Invoice, Invoice, QFilterCondition> {
  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> party(
      FilterQuery<Party> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'party');
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> partyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'party', 0, true, 0, true);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> order(
      FilterQuery<Order> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'order');
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> orderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'order', 0, true, 0, true);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceItems(
      FilterQuery<InvoiceItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'invoiceItems');
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceItemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'invoiceItems', length, true, length, true);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition> invoiceItemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'invoiceItems', 0, true, 0, true);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceItemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'invoiceItems', 0, false, 999999, true);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceItemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'invoiceItems', 0, true, length, include);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceItemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'invoiceItems', length, include, 999999, true);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterFilterCondition>
      invoiceItemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'invoiceItems', lower, includeLower, upper, includeUpper);
    });
  }
}

extension InvoiceQuerySortBy on QueryBuilder<Invoice, Invoice, QSortBy> {
  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCancellationReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancellationReason', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCancellationReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancellationReason', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCancelledBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledBy', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCancelledByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledBy', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCancelledDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledDate', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCancelledDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledDate', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByEditTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editTime', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByEditTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editTime', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByEditedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedBy', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByEditedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedBy', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByGrandTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByGstNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByGstNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByIgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'igstAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByIgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'igstAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByInvoiceDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceDate', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByInvoiceDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceDate', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByInvoiceStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceStatus', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByInvoiceStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceStatus', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByInvoiceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceType', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByInvoiceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceType', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPaidAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPartyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPartyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPartyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPartyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPaymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPaymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPendingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByPendingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByRoundOff() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByRoundOffDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortBySgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortBySgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortBySourceOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceOrderId', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortBySourceOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceOrderId', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortBySourceOrderNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceOrderNumber', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortBySourceOrderNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceOrderNumber', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByTaxableAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxableAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByTaxableAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxableAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByTermsAndConditions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsAndConditions', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByTermsAndConditionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsAndConditions', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByTotalGST() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByTotalGSTDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension InvoiceQuerySortThenBy
    on QueryBuilder<Invoice, Invoice, QSortThenBy> {
  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCancellationReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancellationReason', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCancellationReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancellationReason', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCancelledBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledBy', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCancelledByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledBy', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCancelledDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledDate', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCancelledDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledDate', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByEditTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editTime', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByEditTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editTime', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByEditedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedBy', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByEditedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedBy', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByGrandTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByGstNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByGstNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByIgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'igstAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByIgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'igstAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByInvoiceDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceDate', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByInvoiceDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceDate', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByInvoiceStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceStatus', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByInvoiceStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceStatus', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByInvoiceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceType', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByInvoiceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceType', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPaidAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPartyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPartyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPartyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPartyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPaymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPaymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPendingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByPendingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByRoundOff() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByRoundOffDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenBySgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenBySgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenBySourceOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceOrderId', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenBySourceOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceOrderId', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenBySourceOrderNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceOrderNumber', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenBySourceOrderNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceOrderNumber', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByTaxableAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxableAmount', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByTaxableAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxableAmount', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByTermsAndConditions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsAndConditions', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByTermsAndConditionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsAndConditions', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByTotalGST() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByTotalGSTDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<Invoice, Invoice, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension InvoiceQueryWhereDistinct
    on QueryBuilder<Invoice, Invoice, QDistinct> {
  QueryBuilder<Invoice, Invoice, QDistinct> distinctByAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByCancellationReason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cancellationReason',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByCancelledBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cancelledBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByCancelledDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cancelledDate');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByCgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cgstAmount');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByCreatedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountAmount');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueDate');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByEditTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editTime');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByEditedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'grandTotal');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByGstNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gstNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByIgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'igstAmount');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByInvoiceDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceDate');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByInvoiceNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByInvoiceStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceStatus',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByInvoiceType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paidAmount');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByPartyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partyId');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByPartyName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByPaymentStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentStatus',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByPendingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingAmount');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByRoundOff() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roundOff');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctBySgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sgstAmount');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctBySourceOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceOrderId');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctBySourceOrderNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceOrderNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtotal');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByTaxableAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxableAmount');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByTermsAndConditions(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'termsAndConditions',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByTotalGST() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalGST');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Invoice, Invoice, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension InvoiceQueryProperty
    on QueryBuilder<Invoice, Invoice, QQueryProperty> {
  QueryBuilder<Invoice, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations>
      cancellationReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cancellationReason');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> cancelledByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cancelledBy');
    });
  }

  QueryBuilder<Invoice, DateTime?, QQueryOperations> cancelledDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cancelledDate');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> cgstAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cgstAmount');
    });
  }

  QueryBuilder<Invoice, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> discountAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountAmount');
    });
  }

  QueryBuilder<Invoice, DateTime?, QQueryOperations> dueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueDate');
    });
  }

  QueryBuilder<Invoice, DateTime?, QQueryOperations> editTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editTime');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> editedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editedBy');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> grandTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'grandTotal');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> gstNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gstNumber');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> igstAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'igstAmount');
    });
  }

  QueryBuilder<Invoice, DateTime?, QQueryOperations> invoiceDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceDate');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> invoiceNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceNumber');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> invoiceStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceStatus');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> invoiceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceType');
    });
  }

  QueryBuilder<Invoice, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<Invoice, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> paidAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paidAmount');
    });
  }

  QueryBuilder<Invoice, int?, QQueryOperations> partyIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partyId');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> partyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partyName');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> paymentStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentStatus');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> pendingAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingAmount');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> roundOffProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roundOff');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> sgstAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sgstAmount');
    });
  }

  QueryBuilder<Invoice, int?, QQueryOperations> sourceOrderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceOrderId');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> sourceOrderNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceOrderNumber');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> subtotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtotal');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> taxableAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxableAmount');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations>
      termsAndConditionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'termsAndConditions');
    });
  }

  QueryBuilder<Invoice, double?, QQueryOperations> totalGSTProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalGST');
    });
  }

  QueryBuilder<Invoice, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<Invoice, String?, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<Invoice, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
