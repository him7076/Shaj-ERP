// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_note_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCreditNoteCollection on Isar {
  IsarCollection<CreditNote> get creditNotes => this.collection();
}

const CreditNoteSchema = CollectionSchema(
  name: r'CreditNote',
  id: 266119816388625,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'cgstAmount': PropertySchema(
      id: 1,
      name: r'cgstAmount',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdBy': PropertySchema(
      id: 3,
      name: r'createdBy',
      type: IsarType.string,
    ),
    r'creditNoteDate': PropertySchema(
      id: 4,
      name: r'creditNoteDate',
      type: IsarType.dateTime,
    ),
    r'creditNoteNumber': PropertySchema(
      id: 5,
      name: r'creditNoteNumber',
      type: IsarType.string,
    ),
    r'discountAmount': PropertySchema(
      id: 6,
      name: r'discountAmount',
      type: IsarType.double,
    ),
    r'grandTotal': PropertySchema(
      id: 7,
      name: r'grandTotal',
      type: IsarType.double,
    ),
    r'gstNumber': PropertySchema(
      id: 8,
      name: r'gstNumber',
      type: IsarType.string,
    ),
    r'igstAmount': PropertySchema(
      id: 9,
      name: r'igstAmount',
      type: IsarType.double,
    ),
    r'isDeleted': PropertySchema(
      id: 10,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 11,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'originalInvoiceNumber': PropertySchema(
      id: 12,
      name: r'originalInvoiceNumber',
      type: IsarType.string,
    ),
    r'originalInvoiceUuid': PropertySchema(
      id: 13,
      name: r'originalInvoiceUuid',
      type: IsarType.string,
    ),
    r'partyId': PropertySchema(
      id: 14,
      name: r'partyId',
      type: IsarType.long,
    ),
    r'partyName': PropertySchema(
      id: 15,
      name: r'partyName',
      type: IsarType.string,
    ),
    r'remarks': PropertySchema(
      id: 16,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'roundOff': PropertySchema(
      id: 17,
      name: r'roundOff',
      type: IsarType.double,
    ),
    r'sgstAmount': PropertySchema(
      id: 18,
      name: r'sgstAmount',
      type: IsarType.double,
    ),
    r'subtotal': PropertySchema(
      id: 19,
      name: r'subtotal',
      type: IsarType.double,
    ),
    r'taxableAmount': PropertySchema(
      id: 20,
      name: r'taxableAmount',
      type: IsarType.double,
    ),
    r'totalGST': PropertySchema(
      id: 21,
      name: r'totalGST',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 22,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 23,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 24,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _creditNoteEstimateSize,
  serialize: _creditNoteSerialize,
  deserialize: _creditNoteDeserialize,
  deserializeProp: _creditNoteDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 213439734042772,
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
    r'creditNoteNumber': IndexSchema(
      id: -859822656720859,
      name: r'creditNoteNumber',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'creditNoteNumber',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'party': LinkSchema(
      id: 301369397714656,
      name: r'party',
      target: r'Party',
      single: true,
    ),
    r'creditNoteItems': LinkSchema(
      id: -864478493930310,
      name: r'creditNoteItems',
      target: r'CreditNoteItem',
      single: false,
      linkName: r'creditNote',
    )
  },
  embeddedSchemas: {},
  getId: _creditNoteGetId,
  getLinks: _creditNoteGetLinks,
  attach: _creditNoteAttach,
  version: '3.1.0+1',
);

int _creditNoteEstimateSize(
  CreditNote object,
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
    final value = object.createdBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.creditNoteNumber;
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
    final value = object.originalInvoiceNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.originalInvoiceUuid;
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
    final value = object.uuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _creditNoteSerialize(
  CreditNote object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeDouble(offsets[1], object.cgstAmount);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.createdBy);
  writer.writeDateTime(offsets[4], object.creditNoteDate);
  writer.writeString(offsets[5], object.creditNoteNumber);
  writer.writeDouble(offsets[6], object.discountAmount);
  writer.writeDouble(offsets[7], object.grandTotal);
  writer.writeString(offsets[8], object.gstNumber);
  writer.writeDouble(offsets[9], object.igstAmount);
  writer.writeBool(offsets[10], object.isDeleted);
  writer.writeBool(offsets[11], object.isSynced);
  writer.writeString(offsets[12], object.originalInvoiceNumber);
  writer.writeString(offsets[13], object.originalInvoiceUuid);
  writer.writeLong(offsets[14], object.partyId);
  writer.writeString(offsets[15], object.partyName);
  writer.writeString(offsets[16], object.remarks);
  writer.writeDouble(offsets[17], object.roundOff);
  writer.writeDouble(offsets[18], object.sgstAmount);
  writer.writeDouble(offsets[19], object.subtotal);
  writer.writeDouble(offsets[20], object.taxableAmount);
  writer.writeDouble(offsets[21], object.totalGST);
  writer.writeDateTime(offsets[22], object.updatedAt);
  writer.writeString(offsets[23], object.uuid);
  writer.writeLong(offsets[24], object.version);
}

CreditNote _creditNoteDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CreditNote();
  object.address = reader.readStringOrNull(offsets[0]);
  object.cgstAmount = reader.readDoubleOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.createdBy = reader.readStringOrNull(offsets[3]);
  object.creditNoteDate = reader.readDateTimeOrNull(offsets[4]);
  object.creditNoteNumber = reader.readStringOrNull(offsets[5]);
  object.discountAmount = reader.readDoubleOrNull(offsets[6]);
  object.grandTotal = reader.readDoubleOrNull(offsets[7]);
  object.gstNumber = reader.readStringOrNull(offsets[8]);
  object.id = id;
  object.igstAmount = reader.readDoubleOrNull(offsets[9]);
  object.isDeleted = reader.readBool(offsets[10]);
  object.isSynced = reader.readBool(offsets[11]);
  object.originalInvoiceNumber = reader.readStringOrNull(offsets[12]);
  object.originalInvoiceUuid = reader.readStringOrNull(offsets[13]);
  object.partyId = reader.readLongOrNull(offsets[14]);
  object.partyName = reader.readStringOrNull(offsets[15]);
  object.remarks = reader.readStringOrNull(offsets[16]);
  object.roundOff = reader.readDoubleOrNull(offsets[17]);
  object.sgstAmount = reader.readDoubleOrNull(offsets[18]);
  object.subtotal = reader.readDoubleOrNull(offsets[19]);
  object.taxableAmount = reader.readDoubleOrNull(offsets[20]);
  object.totalGST = reader.readDoubleOrNull(offsets[21]);
  object.updatedAt = reader.readDateTime(offsets[22]);
  object.uuid = reader.readStringOrNull(offsets[23]);
  object.version = reader.readLong(offsets[24]);
  return object;
}

P _creditNoteDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset)) as P;
    case 18:
      return (reader.readDoubleOrNull(offset)) as P;
    case 19:
      return (reader.readDoubleOrNull(offset)) as P;
    case 20:
      return (reader.readDoubleOrNull(offset)) as P;
    case 21:
      return (reader.readDoubleOrNull(offset)) as P;
    case 22:
      return (reader.readDateTime(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _creditNoteGetId(CreditNote object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _creditNoteGetLinks(CreditNote object) {
  return [object.party, object.creditNoteItems];
}

void _creditNoteAttach(IsarCollection<dynamic> col, Id id, CreditNote object) {
  object.id = id;
  object.party.attach(col, col.isar.collection<Party>(), r'party', id);
  object.creditNoteItems.attach(
      col, col.isar.collection<CreditNoteItem>(), r'creditNoteItems', id);
}

extension CreditNoteByIndex on IsarCollection<CreditNote> {
  Future<CreditNote?> getByUuid(String? uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  CreditNote? getByUuidSync(String? uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String? uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String? uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<CreditNote?>> getAllByUuid(List<String?> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<CreditNote?> getAllByUuidSync(List<String?> uuidValues) {
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

  Future<Id> putByUuid(CreditNote object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(CreditNote object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<CreditNote> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<CreditNote> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }

  Future<CreditNote?> getByCreditNoteNumber(String? creditNoteNumber) {
    return getByIndex(r'creditNoteNumber', [creditNoteNumber]);
  }

  CreditNote? getByCreditNoteNumberSync(String? creditNoteNumber) {
    return getByIndexSync(r'creditNoteNumber', [creditNoteNumber]);
  }

  Future<bool> deleteByCreditNoteNumber(String? creditNoteNumber) {
    return deleteByIndex(r'creditNoteNumber', [creditNoteNumber]);
  }

  bool deleteByCreditNoteNumberSync(String? creditNoteNumber) {
    return deleteByIndexSync(r'creditNoteNumber', [creditNoteNumber]);
  }

  Future<List<CreditNote?>> getAllByCreditNoteNumber(
      List<String?> creditNoteNumberValues) {
    final values = creditNoteNumberValues.map((e) => [e]).toList();
    return getAllByIndex(r'creditNoteNumber', values);
  }

  List<CreditNote?> getAllByCreditNoteNumberSync(
      List<String?> creditNoteNumberValues) {
    final values = creditNoteNumberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'creditNoteNumber', values);
  }

  Future<int> deleteAllByCreditNoteNumber(
      List<String?> creditNoteNumberValues) {
    final values = creditNoteNumberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'creditNoteNumber', values);
  }

  int deleteAllByCreditNoteNumberSync(List<String?> creditNoteNumberValues) {
    final values = creditNoteNumberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'creditNoteNumber', values);
  }

  Future<Id> putByCreditNoteNumber(CreditNote object) {
    return putByIndex(r'creditNoteNumber', object);
  }

  Id putByCreditNoteNumberSync(CreditNote object, {bool saveLinks = true}) {
    return putByIndexSync(r'creditNoteNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCreditNoteNumber(List<CreditNote> objects) {
    return putAllByIndex(r'creditNoteNumber', objects);
  }

  List<Id> putAllByCreditNoteNumberSync(List<CreditNote> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'creditNoteNumber', objects,
        saveLinks: saveLinks);
  }
}

extension CreditNoteQueryWhereSort
    on QueryBuilder<CreditNote, CreditNote, QWhere> {
  QueryBuilder<CreditNote, CreditNote, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CreditNoteQueryWhere
    on QueryBuilder<CreditNote, CreditNote, QWhereClause> {
  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause> idBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [null],
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause> uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uuid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause> uuidEqualTo(
      String? uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause> uuidNotEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause>
      creditNoteNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'creditNoteNumber',
        value: [null],
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause>
      creditNoteNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'creditNoteNumber',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause>
      creditNoteNumberEqualTo(String? creditNoteNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'creditNoteNumber',
        value: [creditNoteNumber],
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterWhereClause>
      creditNoteNumberNotEqualTo(String? creditNoteNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'creditNoteNumber',
              lower: [],
              upper: [creditNoteNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'creditNoteNumber',
              lower: [creditNoteNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'creditNoteNumber',
              lower: [creditNoteNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'creditNoteNumber',
              lower: [],
              upper: [creditNoteNumber],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CreditNoteQueryFilter
    on QueryBuilder<CreditNote, CreditNote, QFilterCondition> {
  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> addressEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      addressGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> addressLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> addressBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> addressStartsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> addressEndsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> addressContains(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> addressMatches(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      cgstAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cgstAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      cgstAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cgstAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> cgstAmountEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      cgstAmountGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      cgstAmountLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> cgstAmountBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      createdByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      createdByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> createdByEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      createdByGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> createdByLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> createdByBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      createdByStartsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> createdByEndsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> createdByContains(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> createdByMatches(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'creditNoteDate',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'creditNoteDate',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creditNoteDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'creditNoteDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'creditNoteDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'creditNoteDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'creditNoteNumber',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'creditNoteNumber',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creditNoteNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'creditNoteNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'creditNoteNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'creditNoteNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'creditNoteNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'creditNoteNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'creditNoteNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'creditNoteNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creditNoteNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'creditNoteNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      discountAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'discountAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      discountAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'discountAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      discountAmountEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      discountAmountLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      discountAmountBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      grandTotalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'grandTotal',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      grandTotalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'grandTotal',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> grandTotalEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      grandTotalGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      grandTotalLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> grandTotalBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      gstNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gstNumber',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      gstNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gstNumber',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> gstNumberEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      gstNumberGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> gstNumberLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> gstNumberBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      gstNumberStartsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> gstNumberEndsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> gstNumberContains(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> gstNumberMatches(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      gstNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gstNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      gstNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gstNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      igstAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'igstAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      igstAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'igstAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> igstAmountEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      igstAmountGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      igstAmountLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> igstAmountBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> isDeletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalInvoiceNumber',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalInvoiceNumber',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalInvoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalInvoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalInvoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalInvoiceNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalInvoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalInvoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalInvoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalInvoiceNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalInvoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalInvoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalInvoiceUuid',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalInvoiceUuid',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalInvoiceUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalInvoiceUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalInvoiceUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalInvoiceUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalInvoiceUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalInvoiceUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalInvoiceUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalInvoiceUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalInvoiceUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      originalInvoiceUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalInvoiceUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partyId',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      partyIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partyId',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partyId',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      partyIdGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyIdLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyIdBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      partyNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partyName',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      partyNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partyName',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyNameEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      partyNameGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyNameLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyNameBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      partyNameStartsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyNameEndsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyNameContains(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyNameMatches(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      partyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partyName',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      partyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partyName',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> remarksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      remarksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> remarksEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      remarksGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> remarksLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> remarksBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> remarksStartsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> remarksEndsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> remarksContains(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> remarksMatches(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> roundOffIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'roundOff',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      roundOffIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'roundOff',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> roundOffEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      roundOffGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> roundOffLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> roundOffBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      sgstAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sgstAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      sgstAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sgstAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> sgstAmountEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      sgstAmountGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      sgstAmountLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> sgstAmountBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> subtotalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subtotal',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      subtotalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subtotal',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> subtotalEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      subtotalGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> subtotalLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> subtotalBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      taxableAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'taxableAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      taxableAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'taxableAmount',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      taxableAmountEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      taxableAmountLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      taxableAmountBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> totalGSTIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalGST',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      totalGSTIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalGST',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> totalGSTEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      totalGSTGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> totalGSTLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> totalGSTBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidEqualTo(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidGreaterThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidStartsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidEndsWith(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidContains(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidMatches(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> versionEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> versionLessThan(
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

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> versionBetween(
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

extension CreditNoteQueryObject
    on QueryBuilder<CreditNote, CreditNote, QFilterCondition> {}

extension CreditNoteQueryLinks
    on QueryBuilder<CreditNote, CreditNote, QFilterCondition> {
  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> party(
      FilterQuery<Party> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'party');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> partyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'party', 0, true, 0, true);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition> creditNoteItems(
      FilterQuery<CreditNoteItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'creditNoteItems');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteItemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'creditNoteItems', length, true, length, true);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteItemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'creditNoteItems', 0, true, 0, true);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteItemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'creditNoteItems', 0, false, 999999, true);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteItemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'creditNoteItems', 0, true, length, include);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteItemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'creditNoteItems', length, include, 999999, true);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterFilterCondition>
      creditNoteItemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'creditNoteItems', lower, includeLower, upper, includeUpper);
    });
  }
}

extension CreditNoteQuerySortBy
    on QueryBuilder<CreditNote, CreditNote, QSortBy> {
  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByCgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByCgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByCreditNoteDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditNoteDate', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      sortByCreditNoteDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditNoteDate', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByCreditNoteNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditNoteNumber', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      sortByCreditNoteNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditNoteNumber', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      sortByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByGrandTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByGstNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByGstNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByIgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'igstAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByIgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'igstAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      sortByOriginalInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalInvoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      sortByOriginalInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalInvoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      sortByOriginalInvoiceUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalInvoiceUuid', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      sortByOriginalInvoiceUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalInvoiceUuid', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByPartyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByPartyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByPartyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByPartyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByRoundOff() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByRoundOffDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortBySgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortBySgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByTaxableAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxableAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByTaxableAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxableAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByTotalGST() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByTotalGSTDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension CreditNoteQuerySortThenBy
    on QueryBuilder<CreditNote, CreditNote, QSortThenBy> {
  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByCgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByCgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByCreditNoteDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditNoteDate', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      thenByCreditNoteDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditNoteDate', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByCreditNoteNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditNoteNumber', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      thenByCreditNoteNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditNoteNumber', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      thenByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByGrandTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByGstNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByGstNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstNumber', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByIgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'igstAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByIgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'igstAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      thenByOriginalInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalInvoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      thenByOriginalInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalInvoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      thenByOriginalInvoiceUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalInvoiceUuid', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy>
      thenByOriginalInvoiceUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalInvoiceUuid', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByPartyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByPartyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyId', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByPartyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByPartyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByRoundOff() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByRoundOffDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundOff', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenBySgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenBySgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByTaxableAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxableAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByTaxableAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxableAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByTotalGST() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByTotalGSTDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGST', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension CreditNoteQueryWhereDistinct
    on QueryBuilder<CreditNote, CreditNote, QDistinct> {
  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByCgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cgstAmount');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByCreatedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByCreditNoteDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creditNoteDate');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByCreditNoteNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creditNoteNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountAmount');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'grandTotal');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByGstNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gstNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByIgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'igstAmount');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct>
      distinctByOriginalInvoiceNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalInvoiceNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByOriginalInvoiceUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalInvoiceUuid',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByPartyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partyId');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByPartyName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByRoundOff() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roundOff');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctBySgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sgstAmount');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtotal');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByTaxableAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxableAmount');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByTotalGST() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalGST');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditNote, CreditNote, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension CreditNoteQueryProperty
    on QueryBuilder<CreditNote, CreditNote, QQueryProperty> {
  QueryBuilder<CreditNote, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CreditNote, String?, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<CreditNote, double?, QQueryOperations> cgstAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cgstAmount');
    });
  }

  QueryBuilder<CreditNote, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CreditNote, String?, QQueryOperations> createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<CreditNote, DateTime?, QQueryOperations>
      creditNoteDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creditNoteDate');
    });
  }

  QueryBuilder<CreditNote, String?, QQueryOperations>
      creditNoteNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creditNoteNumber');
    });
  }

  QueryBuilder<CreditNote, double?, QQueryOperations> discountAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountAmount');
    });
  }

  QueryBuilder<CreditNote, double?, QQueryOperations> grandTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'grandTotal');
    });
  }

  QueryBuilder<CreditNote, String?, QQueryOperations> gstNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gstNumber');
    });
  }

  QueryBuilder<CreditNote, double?, QQueryOperations> igstAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'igstAmount');
    });
  }

  QueryBuilder<CreditNote, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<CreditNote, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<CreditNote, String?, QQueryOperations>
      originalInvoiceNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalInvoiceNumber');
    });
  }

  QueryBuilder<CreditNote, String?, QQueryOperations>
      originalInvoiceUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalInvoiceUuid');
    });
  }

  QueryBuilder<CreditNote, int?, QQueryOperations> partyIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partyId');
    });
  }

  QueryBuilder<CreditNote, String?, QQueryOperations> partyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partyName');
    });
  }

  QueryBuilder<CreditNote, String?, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<CreditNote, double?, QQueryOperations> roundOffProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roundOff');
    });
  }

  QueryBuilder<CreditNote, double?, QQueryOperations> sgstAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sgstAmount');
    });
  }

  QueryBuilder<CreditNote, double?, QQueryOperations> subtotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtotal');
    });
  }

  QueryBuilder<CreditNote, double?, QQueryOperations> taxableAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxableAmount');
    });
  }

  QueryBuilder<CreditNote, double?, QQueryOperations> totalGSTProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalGST');
    });
  }

  QueryBuilder<CreditNote, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<CreditNote, String?, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<CreditNote, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
