// Mocks generated by Mockito 5.2.0 from annotations
// in mem/test/mocks.dart.
// Do not manually edit this file.

import 'dart:async' as _i4;

import 'package:mem/mem.dart' as _i2;
import 'package:mem/repositories/mem_repository.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types

class _FakeMem_0 extends _i1.Fake implements _i2.Mem {}

/// A class which mocks [MemRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockMemRepository extends _i1.Mock implements _i3.MemRepository {
  MockMemRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.Mem> receive(Map<String, dynamic>? value) =>
      (super.noSuchMethod(Invocation.method(#receive, [value]),
              returnValue: Future<_i2.Mem>.value(_FakeMem_0()))
          as _i4.Future<_i2.Mem>);
  @override
  _i4.Future<List<_i2.Mem>> ship(bool? archived) =>
      (super.noSuchMethod(Invocation.method(#ship, [archived]),
              returnValue: Future<List<_i2.Mem>>.value(<_i2.Mem>[]))
          as _i4.Future<List<_i2.Mem>>);
  @override
  _i4.Future<_i2.Mem> shipWhereIdIs(dynamic id) => (super.noSuchMethod(
      Invocation.method(#shipWhereIdIs, [id]),
      returnValue: Future<_i2.Mem>.value(_FakeMem_0())) as _i4.Future<_i2.Mem>);
  @override
  _i4.Future<_i2.Mem> update(_i2.Mem? mem) => (super.noSuchMethod(
      Invocation.method(#update, [mem]),
      returnValue: Future<_i2.Mem>.value(_FakeMem_0())) as _i4.Future<_i2.Mem>);
  @override
  _i4.Future<_i2.Mem> archive(_i2.Mem? mem) => (super.noSuchMethod(
      Invocation.method(#archive, [mem]),
      returnValue: Future<_i2.Mem>.value(_FakeMem_0())) as _i4.Future<_i2.Mem>);
  @override
  _i4.Future<bool> discardWhereIdIs(dynamic id) =>
      (super.noSuchMethod(Invocation.method(#discardWhereIdIs, [id]),
          returnValue: Future<bool>.value(false)) as _i4.Future<bool>);
  @override
  _i4.Future<int> discardAll() =>
      (super.noSuchMethod(Invocation.method(#discardAll, []),
          returnValue: Future<int>.value(0)) as _i4.Future<int>);
}
