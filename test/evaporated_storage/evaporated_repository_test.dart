import 'package:fire_bloc/core/option.dart';
import 'package:fire_bloc/core/result.dart';
import 'package:fire_bloc/evaporated_storage/data/evaporated_repository.dart';
import 'package:fire_bloc/evaporated_storage/domain/evaporated_storage.dart';
import 'package:test/test.dart';

part 'mocks.dart';

void main() {
  const testKey = 'test';
  const testValue = {'test': 'test'};

  group('successful remote storage / successful local storage', () {
    _MockEvaporatedStorage local = _MockSuccessfulEvaporatedStorage();
    _MockEvaporatedStorage remote = _MockSuccessfulEvaporatedStorage();
    var repository = EvaporatedRepository(
      localStorage: local,
      remoteStorage: remote,
    );

    setUp(() async {
      local = _MockSuccessfulEvaporatedStorage();
      remote = _MockSuccessfulEvaporatedStorage();
      repository = EvaporatedRepository(
        localStorage: local,
        remoteStorage: remote,
      );
      await repository.testInitialize();
    });

    test('Repository write', () async {
      await repository.write(testKey, testValue);
      expect(local.storage[testKey], testValue);
      expect(remote.storage[testKey], testValue);
    });

    test('Repository delete', () async {
      await repository.write(testKey, testValue);
      expect(local.storage[testKey], testValue);
      expect(remote.storage[testKey], testValue);
      await repository.delete(testKey);
      expect(local.storage[testKey], null);
      expect(remote.storage[testKey], null);
    });

    test('Repository read', () async {
      await repository.write(testKey, testValue);
      final read = await repository.read(testKey);
      switch (read) {
        case Failure():
          fail('repository.read returned Failure');
        case Success(value: final value):
          switch (value) {
            case None():
              fail('repository.read returned None');
            case Some(value: final value):
              expect(value, testValue);
          }
      }
    });

    test('Repository clear', () async {
      await repository.write(testKey, testValue);
      expect(local.storage[testKey], testValue);
      expect(remote.storage[testKey], testValue);
      await repository.clear();
      expect(local.storage[testKey], null);
      expect(remote.storage[testKey], null);
    });
  });

  group('failing remote storage / successful local storage', () {
    _MockEvaporatedStorage local = _MockSuccessfulEvaporatedStorage();
    _MockEvaporatedStorage remote = _MockFailingEvaporatedStorage();
    var repository = EvaporatedRepository(
      localStorage: local,
      remoteStorage: remote,
    );

    setUp(() async {
      local = _MockSuccessfulEvaporatedStorage();
      remote = _MockFailingEvaporatedStorage();
      repository = EvaporatedRepository(
        localStorage: local,
        remoteStorage: remote,
      );
      await repository.testInitialize();
    });

    test('Repository write remote sync', () async {
      await repository.write(testKey, testValue);
      expect(local.storage[testKey], testValue);
      expect(remote.storage[testKey], null);

      final successfulRemote = _MockSuccessfulEvaporatedStorage();
      final successfulRepo = EvaporatedRepository(
        localStorage: local,
        remoteStorage: successfulRemote,
      );
      await successfulRepo
          .testInitialize(EvaporatedRepositoryStatus.syncRequired);

      expect(successfulRemote.storage[testKey], testValue);
    });

    test('Repository delete remote sync', () async {
      final successfulLocal =
          _MockSuccessfulEvaporatedStorage({testKey: testValue});
      final failingRemote = _MockFailingEvaporatedStorage({testKey: testValue});
      final failingRepo = EvaporatedRepository(
        localStorage: successfulLocal,
        remoteStorage: failingRemote,
      );
      await failingRepo.testInitialize();
      await failingRepo.delete(testKey);
      expect(successfulLocal.storage[testKey], null);
      expect(failingRemote.storage[testKey], testValue);
      final successfulRemote =
          _MockSuccessfulEvaporatedStorage({testKey: testValue});
      final successfulRepo = EvaporatedRepository(
        localStorage: successfulLocal,
        remoteStorage: successfulRemote,
      );
      await successfulRepo
          .testInitialize(EvaporatedRepositoryStatus.syncRequired);

      expect(successfulLocal.storage[testKey], null);
      expect(successfulRemote.storage[testKey], null);
    });
  });
}
