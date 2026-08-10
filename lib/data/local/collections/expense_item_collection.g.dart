// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_item_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetExpenseItemCollection on Isar {
  IsarCollection<ExpenseItem> get expenseItems => this.collection();
}

const ExpenseItemSchema = CollectionSchema(
  name: r'ExpenseItem',
  id: 2195748392019482,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'defaultRate': PropertySchema(
      id: 1,
      name: r'defaultRate',
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
    r'itemName': PropertySchema(
      id: 4,
      name: r'itemName',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 6,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 7,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _expenseItemEstimateSize,
  serialize: _expenseItemSerialize,
  deserialize: _expenseItemDeserialize,
  deserializeProp: _expenseItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 8593028475829104,
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
  getId: _expenseItemGetId,
  getLinks: _expenseItemGetLinks,
  attach: _expenseItemAttach,
  version: '3.1.0+1',
);

int _expenseItemEstimateSize(
  ExpenseItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.itemName;
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

void _expenseItemSerialize(
  ExpenseItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDouble(offsets[1], object.defaultRate);
  writer.writeBool(offsets[2], object.isDeleted);
  writer.writeBool(offsets[3], object.isSynced);
  writer.writeString(offsets[4], object.itemName);
  writer.writeDateTime(offsets[5], object.updatedAt);
  writer.writeString(offsets[6], object.uuid);
  writer.writeLong(offsets[7], object.version);
}

ExpenseItem _expenseItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExpenseItem();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.defaultRate = reader.readDoubleOrNull(offsets[1]);
  object.id = id;
  object.isDeleted = reader.readBool(offsets[2]);
  object.isSynced = reader.readBool(offsets[3]);
  object.itemName = reader.readStringOrNull(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  object.uuid = reader.readStringOrNull(offsets[6]);
  object.version = reader.readLong(offsets[7]);
  return object;
}

P _expenseItemDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _expenseItemGetId(ExpenseItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _expenseItemGetLinks(ExpenseItem object) {
  return [];
}

void _expenseItemAttach(IsarCollection<dynamic> col, Id id, ExpenseItem object) {
  object.id = id;
}

extension ExpenseItemByIndex on IsarCollection<ExpenseItem> {
  Future<ExpenseItem?> getByUuid(String? uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  ExpenseItem? getByUuidSync(String? uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }
}

extension ExpenseItemQueryFilter on QueryBuilder<ExpenseItem, ExpenseItem, QFilterCondition> {
  QueryBuilder<ExpenseItem, ExpenseItem, QAfterFilterCondition> isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseItem, ExpenseItem, QAfterFilterCondition> itemNameEqualTo(
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

  QueryBuilder<ExpenseItem, ExpenseItem, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ExpenseItem, ExpenseItem, QAfterFilterCondition> updatedAtGreaterThan(
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
}

extension ExpenseItemQuerySortBy on QueryBuilder<ExpenseItem, ExpenseItem, QSortBy> {
  QueryBuilder<ExpenseItem, ExpenseItem, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}
