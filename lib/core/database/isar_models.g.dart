// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarWorkoutSessionCollection on Isar {
  IsarCollection<IsarWorkoutSession> get isarWorkoutSessions =>
      this.collection();
}

const IsarWorkoutSessionSchema = CollectionSchema(
  name: r'IsarWorkoutSession',
  id: 7601716149776006201,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'endedAt': PropertySchema(
      id: 1,
      name: r'endedAt',
      type: IsarType.dateTime,
    ),
    r'isDraft': PropertySchema(
      id: 2,
      name: r'isDraft',
      type: IsarType.bool,
    ),
    r'planId': PropertySchema(
      id: 3,
      name: r'planId',
      type: IsarType.string,
    ),
    r'planName': PropertySchema(
      id: 4,
      name: r'planName',
      type: IsarType.string,
    ),
    r'startedAt': PropertySchema(
      id: 5,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'updatedAt': PropertySchema(
      id: 6,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 7,
      name: r'userId',
      type: IsarType.string,
    ),
    r'workoutDate': PropertySchema(
      id: 8,
      name: r'workoutDate',
      type: IsarType.dateTime,
    ),
    r'workoutId': PropertySchema(
      id: 9,
      name: r'workoutId',
      type: IsarType.string,
    )
  },
  estimateSize: _isarWorkoutSessionEstimateSize,
  serialize: _isarWorkoutSessionSerialize,
  deserialize: _isarWorkoutSessionDeserialize,
  deserializeProp: _isarWorkoutSessionDeserializeProp,
  idName: r'id',
  indexes: {
    r'workoutId': IndexSchema(
      id: -2481575602404730374,
      name: r'workoutId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'workoutId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'workoutDate': IndexSchema(
      id: -5586023166526116543,
      name: r'workoutDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'workoutDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'exercises': LinkSchema(
      id: 4622388311791254345,
      name: r'exercises',
      target: r'IsarSessionExercise',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _isarWorkoutSessionGetId,
  getLinks: _isarWorkoutSessionGetLinks,
  attach: _isarWorkoutSessionAttach,
  version: '3.1.0+1',
);

int _isarWorkoutSessionEstimateSize(
  IsarWorkoutSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.planId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.planName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  bytesCount += 3 + object.workoutId.length * 3;
  return bytesCount;
}

void _isarWorkoutSessionSerialize(
  IsarWorkoutSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDateTime(offsets[1], object.endedAt);
  writer.writeBool(offsets[2], object.isDraft);
  writer.writeString(offsets[3], object.planId);
  writer.writeString(offsets[4], object.planName);
  writer.writeDateTime(offsets[5], object.startedAt);
  writer.writeDateTime(offsets[6], object.updatedAt);
  writer.writeString(offsets[7], object.userId);
  writer.writeDateTime(offsets[8], object.workoutDate);
  writer.writeString(offsets[9], object.workoutId);
}

IsarWorkoutSession _isarWorkoutSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarWorkoutSession();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.endedAt = reader.readDateTimeOrNull(offsets[1]);
  object.id = id;
  object.isDraft = reader.readBool(offsets[2]);
  object.planId = reader.readStringOrNull(offsets[3]);
  object.planName = reader.readStringOrNull(offsets[4]);
  object.startedAt = reader.readDateTimeOrNull(offsets[5]);
  object.updatedAt = reader.readDateTime(offsets[6]);
  object.userId = reader.readString(offsets[7]);
  object.workoutDate = reader.readDateTime(offsets[8]);
  object.workoutId = reader.readString(offsets[9]);
  return object;
}

P _isarWorkoutSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarWorkoutSessionGetId(IsarWorkoutSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarWorkoutSessionGetLinks(
    IsarWorkoutSession object) {
  return [object.exercises];
}

void _isarWorkoutSessionAttach(
    IsarCollection<dynamic> col, Id id, IsarWorkoutSession object) {
  object.id = id;
  object.exercises.attach(
      col, col.isar.collection<IsarSessionExercise>(), r'exercises', id);
}

extension IsarWorkoutSessionByIndex on IsarCollection<IsarWorkoutSession> {
  Future<IsarWorkoutSession?> getByWorkoutId(String workoutId) {
    return getByIndex(r'workoutId', [workoutId]);
  }

  IsarWorkoutSession? getByWorkoutIdSync(String workoutId) {
    return getByIndexSync(r'workoutId', [workoutId]);
  }

  Future<bool> deleteByWorkoutId(String workoutId) {
    return deleteByIndex(r'workoutId', [workoutId]);
  }

  bool deleteByWorkoutIdSync(String workoutId) {
    return deleteByIndexSync(r'workoutId', [workoutId]);
  }

  Future<List<IsarWorkoutSession?>> getAllByWorkoutId(
      List<String> workoutIdValues) {
    final values = workoutIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'workoutId', values);
  }

  List<IsarWorkoutSession?> getAllByWorkoutIdSync(
      List<String> workoutIdValues) {
    final values = workoutIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'workoutId', values);
  }

  Future<int> deleteAllByWorkoutId(List<String> workoutIdValues) {
    final values = workoutIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'workoutId', values);
  }

  int deleteAllByWorkoutIdSync(List<String> workoutIdValues) {
    final values = workoutIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'workoutId', values);
  }

  Future<Id> putByWorkoutId(IsarWorkoutSession object) {
    return putByIndex(r'workoutId', object);
  }

  Id putByWorkoutIdSync(IsarWorkoutSession object, {bool saveLinks = true}) {
    return putByIndexSync(r'workoutId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByWorkoutId(List<IsarWorkoutSession> objects) {
    return putAllByIndex(r'workoutId', objects);
  }

  List<Id> putAllByWorkoutIdSync(List<IsarWorkoutSession> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'workoutId', objects, saveLinks: saveLinks);
  }
}

extension IsarWorkoutSessionQueryWhereSort
    on QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QWhere> {
  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhere>
      anyWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'workoutDate'),
      );
    });
  }
}

extension IsarWorkoutSessionQueryWhere
    on QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QWhereClause> {
  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      workoutIdEqualTo(String workoutId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'workoutId',
        value: [workoutId],
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      workoutIdNotEqualTo(String workoutId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workoutId',
              lower: [],
              upper: [workoutId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workoutId',
              lower: [workoutId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workoutId',
              lower: [workoutId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workoutId',
              lower: [],
              upper: [workoutId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      userIdEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      userIdNotEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      workoutDateEqualTo(DateTime workoutDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'workoutDate',
        value: [workoutDate],
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      workoutDateNotEqualTo(DateTime workoutDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workoutDate',
              lower: [],
              upper: [workoutDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workoutDate',
              lower: [workoutDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workoutDate',
              lower: [workoutDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workoutDate',
              lower: [],
              upper: [workoutDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      workoutDateGreaterThan(
    DateTime workoutDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'workoutDate',
        lower: [workoutDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      workoutDateLessThan(
    DateTime workoutDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'workoutDate',
        lower: [],
        upper: [workoutDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterWhereClause>
      workoutDateBetween(
    DateTime lowerWorkoutDate,
    DateTime upperWorkoutDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'workoutDate',
        lower: [lowerWorkoutDate],
        includeLower: includeLower,
        upper: [upperWorkoutDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarWorkoutSessionQueryFilter
    on QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QFilterCondition> {
  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      endedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endedAt',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      endedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endedAt',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      endedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      endedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      endedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      endedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      isDraftEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDraft',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'planId',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'planId',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'planId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'planId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'planId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'planName',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'planName',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'planName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'planName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      planNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'planName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      startedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startedAt',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      startedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startedAt',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      startedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      startedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      startedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      startedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workoutDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workoutDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workoutDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workoutId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'workoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'workoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'workoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'workoutId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      workoutIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'workoutId',
        value: '',
      ));
    });
  }
}

extension IsarWorkoutSessionQueryObject
    on QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QFilterCondition> {}

extension IsarWorkoutSessionQueryLinks
    on QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QFilterCondition> {
  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      exercises(FilterQuery<IsarSessionExercise> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'exercises');
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      exercisesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', length, true, length, true);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      exercisesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      exercisesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      exercisesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', 0, true, length, include);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      exercisesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterFilterCondition>
      exercisesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'exercises', lower, includeLower, upper, includeUpper);
    });
  }
}

extension IsarWorkoutSessionQuerySortBy
    on QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QSortBy> {
  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByIsDraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByIsDraftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByPlanId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByPlanIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByWorkoutDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      sortByWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutId', Sort.desc);
    });
  }
}

extension IsarWorkoutSessionQuerySortThenBy
    on QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QSortThenBy> {
  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByIsDraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByIsDraftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByPlanId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByPlanIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByWorkoutDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QAfterSortBy>
      thenByWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutId', Sort.desc);
    });
  }
}

extension IsarWorkoutSessionQueryWhereDistinct
    on QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct> {
  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endedAt');
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByIsDraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDraft');
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByPlanId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'planId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByPlanName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'planName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutDate');
    });
  }

  QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QDistinct>
      distinctByWorkoutId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutId', caseSensitive: caseSensitive);
    });
  }
}

extension IsarWorkoutSessionQueryProperty
    on QueryBuilder<IsarWorkoutSession, IsarWorkoutSession, QQueryProperty> {
  QueryBuilder<IsarWorkoutSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarWorkoutSession, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarWorkoutSession, DateTime?, QQueryOperations>
      endedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endedAt');
    });
  }

  QueryBuilder<IsarWorkoutSession, bool, QQueryOperations> isDraftProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDraft');
    });
  }

  QueryBuilder<IsarWorkoutSession, String?, QQueryOperations> planIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'planId');
    });
  }

  QueryBuilder<IsarWorkoutSession, String?, QQueryOperations>
      planNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'planName');
    });
  }

  QueryBuilder<IsarWorkoutSession, DateTime?, QQueryOperations>
      startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<IsarWorkoutSession, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarWorkoutSession, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<IsarWorkoutSession, DateTime, QQueryOperations>
      workoutDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutDate');
    });
  }

  QueryBuilder<IsarWorkoutSession, String, QQueryOperations>
      workoutIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarSessionExerciseCollection on Isar {
  IsarCollection<IsarSessionExercise> get isarSessionExercises =>
      this.collection();
}

const IsarSessionExerciseSchema = CollectionSchema(
  name: r'IsarSessionExercise',
  id: 7458767335283928244,
  properties: {
    r'directWorkoutId': PropertySchema(
      id: 0,
      name: r'directWorkoutId',
      type: IsarType.string,
    ),
    r'exerciseId': PropertySchema(
      id: 1,
      name: r'exerciseId',
      type: IsarType.string,
    ),
    r'isTemplate': PropertySchema(
      id: 2,
      name: r'isTemplate',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'order': PropertySchema(
      id: 4,
      name: r'order',
      type: IsarType.long,
    ),
    r'skipped': PropertySchema(
      id: 5,
      name: r'skipped',
      type: IsarType.bool,
    ),
    r'userId': PropertySchema(
      id: 6,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _isarSessionExerciseEstimateSize,
  serialize: _isarSessionExerciseSerialize,
  deserialize: _isarSessionExerciseDeserialize,
  deserializeProp: _isarSessionExerciseDeserializeProp,
  idName: r'id',
  indexes: {
    r'exerciseId': IndexSchema(
      id: -5431545612219001672,
      name: r'exerciseId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'exerciseId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'directWorkoutId': IndexSchema(
      id: -7632653349700211794,
      name: r'directWorkoutId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'directWorkoutId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'sets': LinkSchema(
      id: 5952388734380829275,
      name: r'sets',
      target: r'IsarExerciseSet',
      single: false,
    ),
    r'workout': LinkSchema(
      id: -5014372682963767366,
      name: r'workout',
      target: r'IsarWorkoutSession',
      single: true,
      linkName: r'exercises',
    )
  },
  embeddedSchemas: {},
  getId: _isarSessionExerciseGetId,
  getLinks: _isarSessionExerciseGetLinks,
  attach: _isarSessionExerciseAttach,
  version: '3.1.0+1',
);

int _isarSessionExerciseEstimateSize(
  IsarSessionExercise object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.directWorkoutId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.exerciseId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarSessionExerciseSerialize(
  IsarSessionExercise object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.directWorkoutId);
  writer.writeString(offsets[1], object.exerciseId);
  writer.writeBool(offsets[2], object.isTemplate);
  writer.writeString(offsets[3], object.name);
  writer.writeLong(offsets[4], object.order);
  writer.writeBool(offsets[5], object.skipped);
  writer.writeString(offsets[6], object.userId);
}

IsarSessionExercise _isarSessionExerciseDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSessionExercise();
  object.directWorkoutId = reader.readStringOrNull(offsets[0]);
  object.exerciseId = reader.readString(offsets[1]);
  object.id = id;
  object.isTemplate = reader.readBool(offsets[2]);
  object.name = reader.readString(offsets[3]);
  object.order = reader.readLong(offsets[4]);
  object.skipped = reader.readBool(offsets[5]);
  object.userId = reader.readStringOrNull(offsets[6]);
  return object;
}

P _isarSessionExerciseDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarSessionExerciseGetId(IsarSessionExercise object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarSessionExerciseGetLinks(
    IsarSessionExercise object) {
  return [object.sets, object.workout];
}

void _isarSessionExerciseAttach(
    IsarCollection<dynamic> col, Id id, IsarSessionExercise object) {
  object.id = id;
  object.sets.attach(col, col.isar.collection<IsarExerciseSet>(), r'sets', id);
  object.workout
      .attach(col, col.isar.collection<IsarWorkoutSession>(), r'workout', id);
}

extension IsarSessionExerciseByIndex on IsarCollection<IsarSessionExercise> {
  Future<IsarSessionExercise?> getByExerciseId(String exerciseId) {
    return getByIndex(r'exerciseId', [exerciseId]);
  }

  IsarSessionExercise? getByExerciseIdSync(String exerciseId) {
    return getByIndexSync(r'exerciseId', [exerciseId]);
  }

  Future<bool> deleteByExerciseId(String exerciseId) {
    return deleteByIndex(r'exerciseId', [exerciseId]);
  }

  bool deleteByExerciseIdSync(String exerciseId) {
    return deleteByIndexSync(r'exerciseId', [exerciseId]);
  }

  Future<List<IsarSessionExercise?>> getAllByExerciseId(
      List<String> exerciseIdValues) {
    final values = exerciseIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'exerciseId', values);
  }

  List<IsarSessionExercise?> getAllByExerciseIdSync(
      List<String> exerciseIdValues) {
    final values = exerciseIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'exerciseId', values);
  }

  Future<int> deleteAllByExerciseId(List<String> exerciseIdValues) {
    final values = exerciseIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'exerciseId', values);
  }

  int deleteAllByExerciseIdSync(List<String> exerciseIdValues) {
    final values = exerciseIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'exerciseId', values);
  }

  Future<Id> putByExerciseId(IsarSessionExercise object) {
    return putByIndex(r'exerciseId', object);
  }

  Id putByExerciseIdSync(IsarSessionExercise object, {bool saveLinks = true}) {
    return putByIndexSync(r'exerciseId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByExerciseId(List<IsarSessionExercise> objects) {
    return putAllByIndex(r'exerciseId', objects);
  }

  List<Id> putAllByExerciseIdSync(List<IsarSessionExercise> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'exerciseId', objects, saveLinks: saveLinks);
  }
}

extension IsarSessionExerciseQueryWhereSort
    on QueryBuilder<IsarSessionExercise, IsarSessionExercise, QWhere> {
  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarSessionExerciseQueryWhere
    on QueryBuilder<IsarSessionExercise, IsarSessionExercise, QWhereClause> {
  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
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

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      exerciseIdEqualTo(String exerciseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'exerciseId',
        value: [exerciseId],
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      exerciseIdNotEqualTo(String exerciseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseId',
              lower: [],
              upper: [exerciseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseId',
              lower: [exerciseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseId',
              lower: [exerciseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseId',
              lower: [],
              upper: [exerciseId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      userIdEqualTo(String? userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      userIdNotEqualTo(String? userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      directWorkoutIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directWorkoutId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      directWorkoutIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'directWorkoutId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      directWorkoutIdEqualTo(String? directWorkoutId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directWorkoutId',
        value: [directWorkoutId],
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      directWorkoutIdNotEqualTo(String? directWorkoutId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [],
              upper: [directWorkoutId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [directWorkoutId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [directWorkoutId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [],
              upper: [directWorkoutId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterWhereClause>
      nameNotEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarSessionExerciseQueryFilter on QueryBuilder<IsarSessionExercise,
    IsarSessionExercise, QFilterCondition> {
  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'directWorkoutId',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'directWorkoutId',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'directWorkoutId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'directWorkoutId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directWorkoutId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      directWorkoutIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'directWorkoutId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exerciseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      exerciseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
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

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
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

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
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

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      isTemplateEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isTemplate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      orderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      orderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      orderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      orderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'order',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      skippedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skipped',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension IsarSessionExerciseQueryObject on QueryBuilder<IsarSessionExercise,
    IsarSessionExercise, QFilterCondition> {}

extension IsarSessionExerciseQueryLinks on QueryBuilder<IsarSessionExercise,
    IsarSessionExercise, QFilterCondition> {
  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      sets(FilterQuery<IsarExerciseSet> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'sets');
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      setsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sets', length, true, length, true);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      setsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sets', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      setsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sets', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      setsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sets', 0, true, length, include);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      setsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sets', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      setsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'sets', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      workout(FilterQuery<IsarWorkoutSession> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'workout');
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterFilterCondition>
      workoutIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'workout', 0, true, 0, true);
    });
  }
}

extension IsarSessionExerciseQuerySortBy
    on QueryBuilder<IsarSessionExercise, IsarSessionExercise, QSortBy> {
  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByDirectWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByDirectWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByIsTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTemplate', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByIsTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTemplate', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortBySkipped() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipped', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortBySkippedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipped', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension IsarSessionExerciseQuerySortThenBy
    on QueryBuilder<IsarSessionExercise, IsarSessionExercise, QSortThenBy> {
  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByDirectWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByDirectWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByIsTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTemplate', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByIsTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTemplate', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenBySkipped() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipped', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenBySkippedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipped', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension IsarSessionExerciseQueryWhereDistinct
    on QueryBuilder<IsarSessionExercise, IsarSessionExercise, QDistinct> {
  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QDistinct>
      distinctByDirectWorkoutId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'directWorkoutId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QDistinct>
      distinctByExerciseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exerciseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QDistinct>
      distinctByIsTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTemplate');
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QDistinct>
      distinctByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'order');
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QDistinct>
      distinctBySkipped() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skipped');
    });
  }

  QueryBuilder<IsarSessionExercise, IsarSessionExercise, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension IsarSessionExerciseQueryProperty
    on QueryBuilder<IsarSessionExercise, IsarSessionExercise, QQueryProperty> {
  QueryBuilder<IsarSessionExercise, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarSessionExercise, String?, QQueryOperations>
      directWorkoutIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'directWorkoutId');
    });
  }

  QueryBuilder<IsarSessionExercise, String, QQueryOperations>
      exerciseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exerciseId');
    });
  }

  QueryBuilder<IsarSessionExercise, bool, QQueryOperations>
      isTemplateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTemplate');
    });
  }

  QueryBuilder<IsarSessionExercise, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarSessionExercise, int, QQueryOperations> orderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'order');
    });
  }

  QueryBuilder<IsarSessionExercise, bool, QQueryOperations> skippedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skipped');
    });
  }

  QueryBuilder<IsarSessionExercise, String?, QQueryOperations>
      userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarExerciseSetCollection on Isar {
  IsarCollection<IsarExerciseSet> get isarExerciseSets => this.collection();
}

const IsarExerciseSetSchema = CollectionSchema(
  name: r'IsarExerciseSet',
  id: -3868061883612542622,
  properties: {
    r'directExerciseId': PropertySchema(
      id: 0,
      name: r'directExerciseId',
      type: IsarType.string,
    ),
    r'directWorkoutId': PropertySchema(
      id: 1,
      name: r'directWorkoutId',
      type: IsarType.string,
    ),
    r'setId': PropertySchema(
      id: 2,
      name: r'setId',
      type: IsarType.string,
    ),
    r'setNumber': PropertySchema(
      id: 3,
      name: r'setNumber',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 4,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _isarExerciseSetEstimateSize,
  serialize: _isarExerciseSetSerialize,
  deserialize: _isarExerciseSetDeserialize,
  deserializeProp: _isarExerciseSetDeserializeProp,
  idName: r'id',
  indexes: {
    r'setId': IndexSchema(
      id: 2535400842924879452,
      name: r'setId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'setId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'directWorkoutId': IndexSchema(
      id: -7632653349700211794,
      name: r'directWorkoutId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'directWorkoutId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'directExerciseId': IndexSchema(
      id: -1759095358269577304,
      name: r'directExerciseId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'directExerciseId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'segments': LinkSchema(
      id: -2596065131739864260,
      name: r'segments',
      target: r'IsarSetSegment',
      single: false,
    ),
    r'exercise': LinkSchema(
      id: -9116718952474488231,
      name: r'exercise',
      target: r'IsarSessionExercise',
      single: true,
      linkName: r'sets',
    )
  },
  embeddedSchemas: {},
  getId: _isarExerciseSetGetId,
  getLinks: _isarExerciseSetGetLinks,
  attach: _isarExerciseSetAttach,
  version: '3.1.0+1',
);

int _isarExerciseSetEstimateSize(
  IsarExerciseSet object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.directExerciseId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.directWorkoutId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.setId.length * 3;
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarExerciseSetSerialize(
  IsarExerciseSet object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.directExerciseId);
  writer.writeString(offsets[1], object.directWorkoutId);
  writer.writeString(offsets[2], object.setId);
  writer.writeLong(offsets[3], object.setNumber);
  writer.writeString(offsets[4], object.userId);
}

IsarExerciseSet _isarExerciseSetDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarExerciseSet();
  object.directExerciseId = reader.readStringOrNull(offsets[0]);
  object.directWorkoutId = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.setId = reader.readString(offsets[2]);
  object.setNumber = reader.readLong(offsets[3]);
  object.userId = reader.readStringOrNull(offsets[4]);
  return object;
}

P _isarExerciseSetDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarExerciseSetGetId(IsarExerciseSet object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarExerciseSetGetLinks(IsarExerciseSet object) {
  return [object.segments, object.exercise];
}

void _isarExerciseSetAttach(
    IsarCollection<dynamic> col, Id id, IsarExerciseSet object) {
  object.id = id;
  object.segments
      .attach(col, col.isar.collection<IsarSetSegment>(), r'segments', id);
  object.exercise
      .attach(col, col.isar.collection<IsarSessionExercise>(), r'exercise', id);
}

extension IsarExerciseSetByIndex on IsarCollection<IsarExerciseSet> {
  Future<IsarExerciseSet?> getBySetId(String setId) {
    return getByIndex(r'setId', [setId]);
  }

  IsarExerciseSet? getBySetIdSync(String setId) {
    return getByIndexSync(r'setId', [setId]);
  }

  Future<bool> deleteBySetId(String setId) {
    return deleteByIndex(r'setId', [setId]);
  }

  bool deleteBySetIdSync(String setId) {
    return deleteByIndexSync(r'setId', [setId]);
  }

  Future<List<IsarExerciseSet?>> getAllBySetId(List<String> setIdValues) {
    final values = setIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'setId', values);
  }

  List<IsarExerciseSet?> getAllBySetIdSync(List<String> setIdValues) {
    final values = setIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'setId', values);
  }

  Future<int> deleteAllBySetId(List<String> setIdValues) {
    final values = setIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'setId', values);
  }

  int deleteAllBySetIdSync(List<String> setIdValues) {
    final values = setIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'setId', values);
  }

  Future<Id> putBySetId(IsarExerciseSet object) {
    return putByIndex(r'setId', object);
  }

  Id putBySetIdSync(IsarExerciseSet object, {bool saveLinks = true}) {
    return putByIndexSync(r'setId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySetId(List<IsarExerciseSet> objects) {
    return putAllByIndex(r'setId', objects);
  }

  List<Id> putAllBySetIdSync(List<IsarExerciseSet> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'setId', objects, saveLinks: saveLinks);
  }
}

extension IsarExerciseSetQueryWhereSort
    on QueryBuilder<IsarExerciseSet, IsarExerciseSet, QWhere> {
  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarExerciseSetQueryWhere
    on QueryBuilder<IsarExerciseSet, IsarExerciseSet, QWhereClause> {
  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
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

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      setIdEqualTo(String setId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'setId',
        value: [setId],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      setIdNotEqualTo(String setId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'setId',
              lower: [],
              upper: [setId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'setId',
              lower: [setId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'setId',
              lower: [setId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'setId',
              lower: [],
              upper: [setId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      userIdEqualTo(String? userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      userIdNotEqualTo(String? userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      directWorkoutIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directWorkoutId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      directWorkoutIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'directWorkoutId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      directWorkoutIdEqualTo(String? directWorkoutId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directWorkoutId',
        value: [directWorkoutId],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      directWorkoutIdNotEqualTo(String? directWorkoutId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [],
              upper: [directWorkoutId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [directWorkoutId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [directWorkoutId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [],
              upper: [directWorkoutId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      directExerciseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directExerciseId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      directExerciseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'directExerciseId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      directExerciseIdEqualTo(String? directExerciseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directExerciseId',
        value: [directExerciseId],
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterWhereClause>
      directExerciseIdNotEqualTo(String? directExerciseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directExerciseId',
              lower: [],
              upper: [directExerciseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directExerciseId',
              lower: [directExerciseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directExerciseId',
              lower: [directExerciseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directExerciseId',
              lower: [],
              upper: [directExerciseId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarExerciseSetQueryFilter
    on QueryBuilder<IsarExerciseSet, IsarExerciseSet, QFilterCondition> {
  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'directExerciseId',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'directExerciseId',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'directExerciseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'directExerciseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directExerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directExerciseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'directExerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'directWorkoutId',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'directWorkoutId',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'directWorkoutId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'directWorkoutId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directWorkoutId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      directWorkoutIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'directWorkoutId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
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

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
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

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
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

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'setId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'setId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'setId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'setId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'setId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'setId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'setId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'setId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'setId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'setId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'setNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'setNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'setNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      setNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'setNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension IsarExerciseSetQueryObject
    on QueryBuilder<IsarExerciseSet, IsarExerciseSet, QFilterCondition> {}

extension IsarExerciseSetQueryLinks
    on QueryBuilder<IsarExerciseSet, IsarExerciseSet, QFilterCondition> {
  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      segments(FilterQuery<IsarSetSegment> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'segments');
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      segmentsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', length, true, length, true);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      segmentsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      segmentsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      segmentsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', 0, true, length, include);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      segmentsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      segmentsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'segments', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      exercise(FilterQuery<IsarSessionExercise> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'exercise');
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterFilterCondition>
      exerciseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercise', 0, true, 0, true);
    });
  }
}

extension IsarExerciseSetQuerySortBy
    on QueryBuilder<IsarExerciseSet, IsarExerciseSet, QSortBy> {
  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      sortByDirectExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directExerciseId', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      sortByDirectExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directExerciseId', Sort.desc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      sortByDirectWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      sortByDirectWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.desc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy> sortBySetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setId', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      sortBySetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setId', Sort.desc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      sortBySetNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      sortBySetNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension IsarExerciseSetQuerySortThenBy
    on QueryBuilder<IsarExerciseSet, IsarExerciseSet, QSortThenBy> {
  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      thenByDirectExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directExerciseId', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      thenByDirectExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directExerciseId', Sort.desc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      thenByDirectWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      thenByDirectWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.desc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy> thenBySetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setId', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      thenBySetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setId', Sort.desc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      thenBySetNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      thenBySetNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension IsarExerciseSetQueryWhereDistinct
    on QueryBuilder<IsarExerciseSet, IsarExerciseSet, QDistinct> {
  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QDistinct>
      distinctByDirectExerciseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'directExerciseId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QDistinct>
      distinctByDirectWorkoutId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'directWorkoutId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QDistinct> distinctBySetId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'setId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QDistinct>
      distinctBySetNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'setNumber');
    });
  }

  QueryBuilder<IsarExerciseSet, IsarExerciseSet, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension IsarExerciseSetQueryProperty
    on QueryBuilder<IsarExerciseSet, IsarExerciseSet, QQueryProperty> {
  QueryBuilder<IsarExerciseSet, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarExerciseSet, String?, QQueryOperations>
      directExerciseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'directExerciseId');
    });
  }

  QueryBuilder<IsarExerciseSet, String?, QQueryOperations>
      directWorkoutIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'directWorkoutId');
    });
  }

  QueryBuilder<IsarExerciseSet, String, QQueryOperations> setIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'setId');
    });
  }

  QueryBuilder<IsarExerciseSet, int, QQueryOperations> setNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'setNumber');
    });
  }

  QueryBuilder<IsarExerciseSet, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarSetSegmentCollection on Isar {
  IsarCollection<IsarSetSegment> get isarSetSegments => this.collection();
}

const IsarSetSegmentSchema = CollectionSchema(
  name: r'IsarSetSegment',
  id: 2702857223198405679,
  properties: {
    r'directExerciseId': PropertySchema(
      id: 0,
      name: r'directExerciseId',
      type: IsarType.string,
    ),
    r'directSetId': PropertySchema(
      id: 1,
      name: r'directSetId',
      type: IsarType.string,
    ),
    r'directWorkoutId': PropertySchema(
      id: 2,
      name: r'directWorkoutId',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 3,
      name: r'notes',
      type: IsarType.string,
    ),
    r'repsFrom': PropertySchema(
      id: 4,
      name: r'repsFrom',
      type: IsarType.long,
    ),
    r'repsTo': PropertySchema(
      id: 5,
      name: r'repsTo',
      type: IsarType.long,
    ),
    r'segmentId': PropertySchema(
      id: 6,
      name: r'segmentId',
      type: IsarType.string,
    ),
    r'segmentOrder': PropertySchema(
      id: 7,
      name: r'segmentOrder',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 8,
      name: r'userId',
      type: IsarType.string,
    ),
    r'weight': PropertySchema(
      id: 9,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _isarSetSegmentEstimateSize,
  serialize: _isarSetSegmentSerialize,
  deserialize: _isarSetSegmentDeserialize,
  deserializeProp: _isarSetSegmentDeserializeProp,
  idName: r'id',
  indexes: {
    r'segmentId': IndexSchema(
      id: 3500546770579604214,
      name: r'segmentId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'segmentId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'directWorkoutId': IndexSchema(
      id: -7632653349700211794,
      name: r'directWorkoutId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'directWorkoutId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'directExerciseId': IndexSchema(
      id: -1759095358269577304,
      name: r'directExerciseId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'directExerciseId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'directSetId': IndexSchema(
      id: 4908101982265171155,
      name: r'directSetId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'directSetId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'set': LinkSchema(
      id: 2132480913628559318,
      name: r'set',
      target: r'IsarExerciseSet',
      single: true,
      linkName: r'segments',
    )
  },
  embeddedSchemas: {},
  getId: _isarSetSegmentGetId,
  getLinks: _isarSetSegmentGetLinks,
  attach: _isarSetSegmentAttach,
  version: '3.1.0+1',
);

int _isarSetSegmentEstimateSize(
  IsarSetSegment object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.directExerciseId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.directSetId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.directWorkoutId;
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
  bytesCount += 3 + object.segmentId.length * 3;
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarSetSegmentSerialize(
  IsarSetSegment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.directExerciseId);
  writer.writeString(offsets[1], object.directSetId);
  writer.writeString(offsets[2], object.directWorkoutId);
  writer.writeString(offsets[3], object.notes);
  writer.writeLong(offsets[4], object.repsFrom);
  writer.writeLong(offsets[5], object.repsTo);
  writer.writeString(offsets[6], object.segmentId);
  writer.writeLong(offsets[7], object.segmentOrder);
  writer.writeString(offsets[8], object.userId);
  writer.writeDouble(offsets[9], object.weight);
}

IsarSetSegment _isarSetSegmentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSetSegment();
  object.directExerciseId = reader.readStringOrNull(offsets[0]);
  object.directSetId = reader.readStringOrNull(offsets[1]);
  object.directWorkoutId = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.notes = reader.readStringOrNull(offsets[3]);
  object.repsFrom = reader.readLong(offsets[4]);
  object.repsTo = reader.readLong(offsets[5]);
  object.segmentId = reader.readString(offsets[6]);
  object.segmentOrder = reader.readLong(offsets[7]);
  object.userId = reader.readStringOrNull(offsets[8]);
  object.weight = reader.readDouble(offsets[9]);
  return object;
}

P _isarSetSegmentDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarSetSegmentGetId(IsarSetSegment object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarSetSegmentGetLinks(IsarSetSegment object) {
  return [object.set];
}

void _isarSetSegmentAttach(
    IsarCollection<dynamic> col, Id id, IsarSetSegment object) {
  object.id = id;
  object.set.attach(col, col.isar.collection<IsarExerciseSet>(), r'set', id);
}

extension IsarSetSegmentByIndex on IsarCollection<IsarSetSegment> {
  Future<IsarSetSegment?> getBySegmentId(String segmentId) {
    return getByIndex(r'segmentId', [segmentId]);
  }

  IsarSetSegment? getBySegmentIdSync(String segmentId) {
    return getByIndexSync(r'segmentId', [segmentId]);
  }

  Future<bool> deleteBySegmentId(String segmentId) {
    return deleteByIndex(r'segmentId', [segmentId]);
  }

  bool deleteBySegmentIdSync(String segmentId) {
    return deleteByIndexSync(r'segmentId', [segmentId]);
  }

  Future<List<IsarSetSegment?>> getAllBySegmentId(
      List<String> segmentIdValues) {
    final values = segmentIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'segmentId', values);
  }

  List<IsarSetSegment?> getAllBySegmentIdSync(List<String> segmentIdValues) {
    final values = segmentIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'segmentId', values);
  }

  Future<int> deleteAllBySegmentId(List<String> segmentIdValues) {
    final values = segmentIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'segmentId', values);
  }

  int deleteAllBySegmentIdSync(List<String> segmentIdValues) {
    final values = segmentIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'segmentId', values);
  }

  Future<Id> putBySegmentId(IsarSetSegment object) {
    return putByIndex(r'segmentId', object);
  }

  Id putBySegmentIdSync(IsarSetSegment object, {bool saveLinks = true}) {
    return putByIndexSync(r'segmentId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySegmentId(List<IsarSetSegment> objects) {
    return putAllByIndex(r'segmentId', objects);
  }

  List<Id> putAllBySegmentIdSync(List<IsarSetSegment> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'segmentId', objects, saveLinks: saveLinks);
  }
}

extension IsarSetSegmentQueryWhereSort
    on QueryBuilder<IsarSetSegment, IsarSetSegment, QWhere> {
  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarSetSegmentQueryWhere
    on QueryBuilder<IsarSetSegment, IsarSetSegment, QWhereClause> {
  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      segmentIdEqualTo(String segmentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'segmentId',
        value: [segmentId],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      segmentIdNotEqualTo(String segmentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'segmentId',
              lower: [],
              upper: [segmentId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'segmentId',
              lower: [segmentId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'segmentId',
              lower: [segmentId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'segmentId',
              lower: [],
              upper: [segmentId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause> userIdEqualTo(
      String? userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      userIdNotEqualTo(String? userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directWorkoutIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directWorkoutId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directWorkoutIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'directWorkoutId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directWorkoutIdEqualTo(String? directWorkoutId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directWorkoutId',
        value: [directWorkoutId],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directWorkoutIdNotEqualTo(String? directWorkoutId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [],
              upper: [directWorkoutId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [directWorkoutId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [directWorkoutId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directWorkoutId',
              lower: [],
              upper: [directWorkoutId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directExerciseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directExerciseId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directExerciseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'directExerciseId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directExerciseIdEqualTo(String? directExerciseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directExerciseId',
        value: [directExerciseId],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directExerciseIdNotEqualTo(String? directExerciseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directExerciseId',
              lower: [],
              upper: [directExerciseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directExerciseId',
              lower: [directExerciseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directExerciseId',
              lower: [directExerciseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directExerciseId',
              lower: [],
              upper: [directExerciseId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directSetIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directSetId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directSetIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'directSetId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directSetIdEqualTo(String? directSetId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directSetId',
        value: [directSetId],
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterWhereClause>
      directSetIdNotEqualTo(String? directSetId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directSetId',
              lower: [],
              upper: [directSetId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directSetId',
              lower: [directSetId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directSetId',
              lower: [directSetId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directSetId',
              lower: [],
              upper: [directSetId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarSetSegmentQueryFilter
    on QueryBuilder<IsarSetSegment, IsarSetSegment, QFilterCondition> {
  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'directExerciseId',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'directExerciseId',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'directExerciseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'directExerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'directExerciseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directExerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directExerciseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'directExerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'directSetId',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'directSetId',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'directSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'directSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'directSetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'directSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'directSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'directSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'directSetId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directSetId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directSetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'directSetId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'directWorkoutId',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'directWorkoutId',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'directWorkoutId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'directWorkoutId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'directWorkoutId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directWorkoutId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      directWorkoutIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'directWorkoutId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
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

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
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

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      repsFromEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repsFrom',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      repsFromGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repsFrom',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      repsFromLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repsFrom',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      repsFromBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repsFrom',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      repsToEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repsTo',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      repsToGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repsTo',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      repsToLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repsTo',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      repsToBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repsTo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'segmentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'segmentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'segmentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'segmentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'segmentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'segmentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'segmentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'segmentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'segmentId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'segmentId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'segmentOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentOrderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'segmentOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentOrderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'segmentOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      segmentOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'segmentOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      weightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      weightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      weightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      weightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension IsarSetSegmentQueryObject
    on QueryBuilder<IsarSetSegment, IsarSetSegment, QFilterCondition> {}

extension IsarSetSegmentQueryLinks
    on QueryBuilder<IsarSetSegment, IsarSetSegment, QFilterCondition> {
  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition> set(
      FilterQuery<IsarExerciseSet> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'set');
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterFilterCondition>
      setIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'set', 0, true, 0, true);
    });
  }
}

extension IsarSetSegmentQuerySortBy
    on QueryBuilder<IsarSetSegment, IsarSetSegment, QSortBy> {
  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByDirectExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directExerciseId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByDirectExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directExerciseId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByDirectSetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directSetId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByDirectSetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directSetId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByDirectWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByDirectWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> sortByRepsFrom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repsFrom', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByRepsFromDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repsFrom', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> sortByRepsTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repsTo', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByRepsToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repsTo', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> sortBySegmentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortBySegmentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortBySegmentOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentOrder', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortBySegmentOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentOrder', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension IsarSetSegmentQuerySortThenBy
    on QueryBuilder<IsarSetSegment, IsarSetSegment, QSortThenBy> {
  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByDirectExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directExerciseId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByDirectExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directExerciseId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByDirectSetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directSetId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByDirectSetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directSetId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByDirectWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByDirectWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directWorkoutId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> thenByRepsFrom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repsFrom', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByRepsFromDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repsFrom', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> thenByRepsTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repsTo', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByRepsToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repsTo', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> thenBySegmentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenBySegmentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenBySegmentOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentOrder', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenBySegmentOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentOrder', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QAfterSortBy>
      thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension IsarSetSegmentQueryWhereDistinct
    on QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct> {
  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct>
      distinctByDirectExerciseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'directExerciseId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct> distinctByDirectSetId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'directSetId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct>
      distinctByDirectWorkoutId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'directWorkoutId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct> distinctByRepsFrom() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repsFrom');
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct> distinctByRepsTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repsTo');
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct> distinctBySegmentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'segmentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct>
      distinctBySegmentOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'segmentOrder');
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSetSegment, IsarSetSegment, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension IsarSetSegmentQueryProperty
    on QueryBuilder<IsarSetSegment, IsarSetSegment, QQueryProperty> {
  QueryBuilder<IsarSetSegment, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarSetSegment, String?, QQueryOperations>
      directExerciseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'directExerciseId');
    });
  }

  QueryBuilder<IsarSetSegment, String?, QQueryOperations>
      directSetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'directSetId');
    });
  }

  QueryBuilder<IsarSetSegment, String?, QQueryOperations>
      directWorkoutIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'directWorkoutId');
    });
  }

  QueryBuilder<IsarSetSegment, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<IsarSetSegment, int, QQueryOperations> repsFromProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repsFrom');
    });
  }

  QueryBuilder<IsarSetSegment, int, QQueryOperations> repsToProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repsTo');
    });
  }

  QueryBuilder<IsarSetSegment, String, QQueryOperations> segmentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'segmentId');
    });
  }

  QueryBuilder<IsarSetSegment, int, QQueryOperations> segmentOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'segmentOrder');
    });
  }

  QueryBuilder<IsarSetSegment, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<IsarSetSegment, double, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPreferenceCollection on Isar {
  IsarCollection<IsarPreference> get isarPreferences => this.collection();
}

const IsarPreferenceSchema = CollectionSchema(
  name: r'IsarPreference',
  id: 6261249172894852306,
  properties: {
    r'key': PropertySchema(
      id: 0,
      name: r'key',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 1,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'value': PropertySchema(
      id: 2,
      name: r'value',
      type: IsarType.string,
    )
  },
  estimateSize: _isarPreferenceEstimateSize,
  serialize: _isarPreferenceSerialize,
  deserialize: _isarPreferenceDeserialize,
  deserializeProp: _isarPreferenceDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarPreferenceGetId,
  getLinks: _isarPreferenceGetLinks,
  attach: _isarPreferenceAttach,
  version: '3.1.0+1',
);

int _isarPreferenceEstimateSize(
  IsarPreference object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.value.length * 3;
  return bytesCount;
}

void _isarPreferenceSerialize(
  IsarPreference object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.key);
  writer.writeDateTime(offsets[1], object.updatedAt);
  writer.writeString(offsets[2], object.value);
}

IsarPreference _isarPreferenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPreference();
  object.id = id;
  object.key = reader.readString(offsets[0]);
  object.updatedAt = reader.readDateTime(offsets[1]);
  object.value = reader.readString(offsets[2]);
  return object;
}

P _isarPreferenceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarPreferenceGetId(IsarPreference object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarPreferenceGetLinks(IsarPreference object) {
  return [];
}

void _isarPreferenceAttach(
    IsarCollection<dynamic> col, Id id, IsarPreference object) {
  object.id = id;
}

extension IsarPreferenceByIndex on IsarCollection<IsarPreference> {
  Future<IsarPreference?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  IsarPreference? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<IsarPreference?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<IsarPreference?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(IsarPreference object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(IsarPreference object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<IsarPreference> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<IsarPreference> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension IsarPreferenceQueryWhereSort
    on QueryBuilder<IsarPreference, IsarPreference, QWhere> {
  QueryBuilder<IsarPreference, IsarPreference, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarPreferenceQueryWhere
    on QueryBuilder<IsarPreference, IsarPreference, QWhereClause> {
  QueryBuilder<IsarPreference, IsarPreference, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<IsarPreference, IsarPreference, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarPreference, IsarPreference, QAfterWhereClause> keyEqualTo(
      String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'key',
        value: [key],
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterWhereClause> keyNotEqualTo(
      String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarPreferenceQueryFilter
    on QueryBuilder<IsarPreference, IsarPreference, QFilterCondition> {
  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
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

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
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

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'key',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
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

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
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

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
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

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'value',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'value',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterFilterCondition>
      valueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'value',
        value: '',
      ));
    });
  }
}

extension IsarPreferenceQueryObject
    on QueryBuilder<IsarPreference, IsarPreference, QFilterCondition> {}

extension IsarPreferenceQueryLinks
    on QueryBuilder<IsarPreference, IsarPreference, QFilterCondition> {}

extension IsarPreferenceQuerySortBy
    on QueryBuilder<IsarPreference, IsarPreference, QSortBy> {
  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension IsarPreferenceQuerySortThenBy
    on QueryBuilder<IsarPreference, IsarPreference, QSortThenBy> {
  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QAfterSortBy> thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension IsarPreferenceQueryWhereDistinct
    on QueryBuilder<IsarPreference, IsarPreference, QDistinct> {
  QueryBuilder<IsarPreference, IsarPreference, QDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarPreference, IsarPreference, QDistinct> distinctByValue(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value', caseSensitive: caseSensitive);
    });
  }
}

extension IsarPreferenceQueryProperty
    on QueryBuilder<IsarPreference, IsarPreference, QQueryProperty> {
  QueryBuilder<IsarPreference, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPreference, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<IsarPreference, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarPreference, String, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarWorkoutPlanCollection on Isar {
  IsarCollection<IsarWorkoutPlan> get isarWorkoutPlans => this.collection();
}

const IsarWorkoutPlanSchema = CollectionSchema(
  name: r'IsarWorkoutPlan',
  id: 3222959159446697829,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'planId': PropertySchema(
      id: 3,
      name: r'planId',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 4,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 5,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _isarWorkoutPlanEstimateSize,
  serialize: _isarWorkoutPlanSerialize,
  deserialize: _isarWorkoutPlanDeserialize,
  deserializeProp: _isarWorkoutPlanDeserializeProp,
  idName: r'id',
  indexes: {
    r'planId': IndexSchema(
      id: 7282644713036731817,
      name: r'planId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'planId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'exercises': LinkSchema(
      id: -2052798493522485012,
      name: r'exercises',
      target: r'IsarPlanExercise',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _isarWorkoutPlanGetId,
  getLinks: _isarWorkoutPlanGetLinks,
  attach: _isarWorkoutPlanAttach,
  version: '3.1.0+1',
);

int _isarWorkoutPlanEstimateSize(
  IsarWorkoutPlan object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.planId.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _isarWorkoutPlanSerialize(
  IsarWorkoutPlan object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.description);
  writer.writeString(offsets[2], object.name);
  writer.writeString(offsets[3], object.planId);
  writer.writeDateTime(offsets[4], object.updatedAt);
  writer.writeString(offsets[5], object.userId);
}

IsarWorkoutPlan _isarWorkoutPlanDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarWorkoutPlan();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.description = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.name = reader.readString(offsets[2]);
  object.planId = reader.readString(offsets[3]);
  object.updatedAt = reader.readDateTime(offsets[4]);
  object.userId = reader.readString(offsets[5]);
  return object;
}

P _isarWorkoutPlanDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarWorkoutPlanGetId(IsarWorkoutPlan object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarWorkoutPlanGetLinks(IsarWorkoutPlan object) {
  return [object.exercises];
}

void _isarWorkoutPlanAttach(
    IsarCollection<dynamic> col, Id id, IsarWorkoutPlan object) {
  object.id = id;
  object.exercises
      .attach(col, col.isar.collection<IsarPlanExercise>(), r'exercises', id);
}

extension IsarWorkoutPlanByIndex on IsarCollection<IsarWorkoutPlan> {
  Future<IsarWorkoutPlan?> getByPlanId(String planId) {
    return getByIndex(r'planId', [planId]);
  }

  IsarWorkoutPlan? getByPlanIdSync(String planId) {
    return getByIndexSync(r'planId', [planId]);
  }

  Future<bool> deleteByPlanId(String planId) {
    return deleteByIndex(r'planId', [planId]);
  }

  bool deleteByPlanIdSync(String planId) {
    return deleteByIndexSync(r'planId', [planId]);
  }

  Future<List<IsarWorkoutPlan?>> getAllByPlanId(List<String> planIdValues) {
    final values = planIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'planId', values);
  }

  List<IsarWorkoutPlan?> getAllByPlanIdSync(List<String> planIdValues) {
    final values = planIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'planId', values);
  }

  Future<int> deleteAllByPlanId(List<String> planIdValues) {
    final values = planIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'planId', values);
  }

  int deleteAllByPlanIdSync(List<String> planIdValues) {
    final values = planIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'planId', values);
  }

  Future<Id> putByPlanId(IsarWorkoutPlan object) {
    return putByIndex(r'planId', object);
  }

  Id putByPlanIdSync(IsarWorkoutPlan object, {bool saveLinks = true}) {
    return putByIndexSync(r'planId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPlanId(List<IsarWorkoutPlan> objects) {
    return putAllByIndex(r'planId', objects);
  }

  List<Id> putAllByPlanIdSync(List<IsarWorkoutPlan> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'planId', objects, saveLinks: saveLinks);
  }
}

extension IsarWorkoutPlanQueryWhereSort
    on QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QWhere> {
  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarWorkoutPlanQueryWhere
    on QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QWhereClause> {
  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterWhereClause>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterWhereClause>
      planIdEqualTo(String planId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'planId',
        value: [planId],
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterWhereClause>
      planIdNotEqualTo(String planId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'planId',
              lower: [],
              upper: [planId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'planId',
              lower: [planId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'planId',
              lower: [planId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'planId',
              lower: [],
              upper: [planId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarWorkoutPlanQueryFilter
    on QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QFilterCondition> {
  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'planId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'planId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      planIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'planId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension IsarWorkoutPlanQueryObject
    on QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QFilterCondition> {}

extension IsarWorkoutPlanQueryLinks
    on QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QFilterCondition> {
  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      exercises(FilterQuery<IsarPlanExercise> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'exercises');
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      exercisesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', length, true, length, true);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      exercisesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      exercisesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      exercisesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', 0, true, length, include);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      exercisesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'exercises', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterFilterCondition>
      exercisesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'exercises', lower, includeLower, upper, includeUpper);
    });
  }
}

extension IsarWorkoutPlanQuerySortBy
    on QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QSortBy> {
  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy> sortByPlanId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      sortByPlanIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension IsarWorkoutPlanQuerySortThenBy
    on QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QSortThenBy> {
  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy> thenByPlanId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      thenByPlanIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension IsarWorkoutPlanQueryWhereDistinct
    on QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QDistinct> {
  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QDistinct> distinctByPlanId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'planId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension IsarWorkoutPlanQueryProperty
    on QueryBuilder<IsarWorkoutPlan, IsarWorkoutPlan, QQueryProperty> {
  QueryBuilder<IsarWorkoutPlan, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarWorkoutPlan, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarWorkoutPlan, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<IsarWorkoutPlan, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarWorkoutPlan, String, QQueryOperations> planIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'planId');
    });
  }

  QueryBuilder<IsarWorkoutPlan, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarWorkoutPlan, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPlanExerciseCollection on Isar {
  IsarCollection<IsarPlanExercise> get isarPlanExercises => this.collection();
}

const IsarPlanExerciseSchema = CollectionSchema(
  name: r'IsarPlanExercise',
  id: -9050799024561492787,
  properties: {
    r'directPlanId': PropertySchema(
      id: 0,
      name: r'directPlanId',
      type: IsarType.string,
    ),
    r'exerciseId': PropertySchema(
      id: 1,
      name: r'exerciseId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'order': PropertySchema(
      id: 3,
      name: r'order',
      type: IsarType.long,
    )
  },
  estimateSize: _isarPlanExerciseEstimateSize,
  serialize: _isarPlanExerciseSerialize,
  deserialize: _isarPlanExerciseDeserialize,
  deserializeProp: _isarPlanExerciseDeserializeProp,
  idName: r'id',
  indexes: {
    r'directPlanId': IndexSchema(
      id: 3138129808092299929,
      name: r'directPlanId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'directPlanId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'plan': LinkSchema(
      id: -7127849685836608727,
      name: r'plan',
      target: r'IsarWorkoutPlan',
      single: true,
      linkName: r'exercises',
    )
  },
  embeddedSchemas: {},
  getId: _isarPlanExerciseGetId,
  getLinks: _isarPlanExerciseGetLinks,
  attach: _isarPlanExerciseAttach,
  version: '3.1.0+1',
);

int _isarPlanExerciseEstimateSize(
  IsarPlanExercise object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.directPlanId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.exerciseId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _isarPlanExerciseSerialize(
  IsarPlanExercise object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.directPlanId);
  writer.writeString(offsets[1], object.exerciseId);
  writer.writeString(offsets[2], object.name);
  writer.writeLong(offsets[3], object.order);
}

IsarPlanExercise _isarPlanExerciseDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPlanExercise();
  object.directPlanId = reader.readStringOrNull(offsets[0]);
  object.exerciseId = reader.readString(offsets[1]);
  object.id = id;
  object.name = reader.readString(offsets[2]);
  object.order = reader.readLong(offsets[3]);
  return object;
}

P _isarPlanExerciseDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarPlanExerciseGetId(IsarPlanExercise object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarPlanExerciseGetLinks(IsarPlanExercise object) {
  return [object.plan];
}

void _isarPlanExerciseAttach(
    IsarCollection<dynamic> col, Id id, IsarPlanExercise object) {
  object.id = id;
  object.plan.attach(col, col.isar.collection<IsarWorkoutPlan>(), r'plan', id);
}

extension IsarPlanExerciseQueryWhereSort
    on QueryBuilder<IsarPlanExercise, IsarPlanExercise, QWhere> {
  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarPlanExerciseQueryWhere
    on QueryBuilder<IsarPlanExercise, IsarPlanExercise, QWhereClause> {
  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhereClause>
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

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhereClause>
      directPlanIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directPlanId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhereClause>
      directPlanIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'directPlanId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhereClause>
      directPlanIdEqualTo(String? directPlanId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'directPlanId',
        value: [directPlanId],
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterWhereClause>
      directPlanIdNotEqualTo(String? directPlanId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directPlanId',
              lower: [],
              upper: [directPlanId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directPlanId',
              lower: [directPlanId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directPlanId',
              lower: [directPlanId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'directPlanId',
              lower: [],
              upper: [directPlanId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarPlanExerciseQueryFilter
    on QueryBuilder<IsarPlanExercise, IsarPlanExercise, QFilterCondition> {
  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'directPlanId',
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'directPlanId',
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directPlanId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'directPlanId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'directPlanId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'directPlanId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'directPlanId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'directPlanId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'directPlanId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'directPlanId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'directPlanId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      directPlanIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'directPlanId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exerciseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      exerciseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
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

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
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

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
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

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      orderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      orderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      orderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      orderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'order',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarPlanExerciseQueryObject
    on QueryBuilder<IsarPlanExercise, IsarPlanExercise, QFilterCondition> {}

extension IsarPlanExerciseQueryLinks
    on QueryBuilder<IsarPlanExercise, IsarPlanExercise, QFilterCondition> {
  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition> plan(
      FilterQuery<IsarWorkoutPlan> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'plan');
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterFilterCondition>
      planIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'plan', 0, true, 0, true);
    });
  }
}

extension IsarPlanExerciseQuerySortBy
    on QueryBuilder<IsarPlanExercise, IsarPlanExercise, QSortBy> {
  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      sortByDirectPlanId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directPlanId', Sort.asc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      sortByDirectPlanIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directPlanId', Sort.desc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      sortByExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.asc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      sortByExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.desc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy> sortByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      sortByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }
}

extension IsarPlanExerciseQuerySortThenBy
    on QueryBuilder<IsarPlanExercise, IsarPlanExercise, QSortThenBy> {
  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      thenByDirectPlanId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directPlanId', Sort.asc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      thenByDirectPlanIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directPlanId', Sort.desc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      thenByExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.asc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      thenByExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.desc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy> thenByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QAfterSortBy>
      thenByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }
}

extension IsarPlanExerciseQueryWhereDistinct
    on QueryBuilder<IsarPlanExercise, IsarPlanExercise, QDistinct> {
  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QDistinct>
      distinctByDirectPlanId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'directPlanId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QDistinct>
      distinctByExerciseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exerciseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPlanExercise, IsarPlanExercise, QDistinct>
      distinctByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'order');
    });
  }
}

extension IsarPlanExerciseQueryProperty
    on QueryBuilder<IsarPlanExercise, IsarPlanExercise, QQueryProperty> {
  QueryBuilder<IsarPlanExercise, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPlanExercise, String?, QQueryOperations>
      directPlanIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'directPlanId');
    });
  }

  QueryBuilder<IsarPlanExercise, String, QQueryOperations>
      exerciseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exerciseId');
    });
  }

  QueryBuilder<IsarPlanExercise, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarPlanExercise, int, QQueryOperations> orderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'order');
    });
  }
}
