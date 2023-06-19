An extension to [package:bloc](https://github.com/felangel/bloc) which automatically persists and
restores bloc and cubit states locally and remotely (Firestore by default). Built to work
with [package:bloc](https://pub.dev/packages/bloc). Heavily inspired
by [package:hydrated_bloc](https://pub.dev/packages/hydrated_bloc).

**Learn more at [bloclibrary.dev](https://bloclibrary.dev)!**

---

## Overview

`fire_bloc` exports an `EvaporatedStorage` interface, which means it can work with any storage
provider. Out of the box, it comes with its own implementations: `FirestoreEvaporatedStorage`
and `HiveEvaporatedStorage`.

The mediation between the local storage and the remote storage is performed
by `EvaporatedRepository`, which also implements `EvaporatedStorage`. If you require special
mediation logic, you can create your own repository and assign that
to `EvaporatedRepository.instance`. However, `EvaporatedRepository` should suffice
for most users.

`HiveEvaporatedStorage` is built on top of [hive](https://pub.dev/packages/hive) for a
platform-agnostic, performant storage layer.

The implementations provided by `fire_bloc` store the state for each user and thus require a user
authenticated through Firebase Auth in order to function. Every user gets their own collection
in Firestore. Each of those collections contains the state of every `FireBloc` and `FireCubit`.

Since the state of `FireBloc` and `FireCubit` may be loaded over network, there is no way to
guarantee that the state is available when first accessed. Therefore, the state is wrapped by
a sealed class `Option`.

```dart
sealed class Option<State> {}

class Some<State> implements Option<State> {
  const Some(this.value);

  final State value;
}

class None<State> implements Option<State> {
  const None();
}
```

When you access the state of `FireBloc` or `FireCubit`, you need to `switch` on the state to
check whether it is already available. Once the state is `Some`, it will not go back to `None`
until the bloc/cubit is closed.

## Usage

### Setup

Your project needs to be connected to a Firebase project that uses Firestore and Authentication.

Your Firestore rules need to allow each user to read from and write to their own collection.

```
rules_version = '2';

service cloud.firestore {
    match /databases/{database}/documents {
        // Each user can read and write documents in their own collection.
        match /{userId}/{document=**} {
            allow read, write: if request.auth != null && request.auth.uid == userId;
        }
    }
}
```

In your main function, you need to set up the storage that is used by `FireBloc` and `FireCubit`.
The intended way of doing this is

1. Instantiate the local storage and the remote storage.
2. Instantiate the repository that is going to mediate between the two.
3. Assign the repository to `EvaporatedRepository.instance` and initialize it.

Since `EvaporatedRepository.instance` is just of type `EvaporatedStorage`, you could
choose to only use remote or local storage by just assigning a local storage implementation. Or you
could go into a totally different direction. If you are uncertain about any of this though, just
ignore the last two sentences and follow along the recommended way of using this package:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final remoteStorage = FirestoreEvaporatedStorage(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );

  final localStorage = HiveEvaporatedStorage.instance();

  EvaporatedRepository.instance = EvaporatedRepository(
    localStorage: localStorage,
    remoteStorage: remoteStorage,
  );

  await EvaporatedRepository.instance.initialize();

  runApp(const MyApp());
}
```

### Create a FireCubit

```dart
class CounterCubit extends FireCubit<int> {
  CounterCubit() : super(const Some(0));

  void increment() {
    switch (state) {
      case Some(value: final value):
        fireEmit(value + 1);
      case None():
    }
  }

  @override
  int? fromJson(Map<String, dynamic> json) =>
      switch (json['value']) {
        final int value => value,
        _ => null,
      };

  @override
  Map<String, dynamic>? toJson(int state) => {'value': state};
}
```

### Create a FireBloc

```dart
sealed class CounterEvent {}

final class CounterIncrementPressed extends CounterEvent {}

class CounterBloc extends FireBloc<CounterEvent, int> {
  CounterBloc() : super(const Some(0)) {
    fireOn<CounterEvent>((event, fireEmit) {
      switch (state) {
        case Some(value: final value):
          switch (event) {
            case CounterIncrementPressed():
              fireEmit(value + 1);
          }
        case None():
          break;
      }
    });
  }

  @override
  int? fromJson(Map<String, dynamic> json) =>
      switch (json['value']) {
        final int value => value,
        _ => null,
      };

  @override
  Map<String, dynamic>? toJson(int state) => {'value': state};
}
```

Now the `CounterCubit` and `CounterBloc` will automatically persist/restore their state. We can
increment the counter value, hot restart, kill the app, etc... and the previous state will be
retained. We can also start the app on a different device or reinstall the app, and the state will
still be available.

The mediation between the remote storage and the local storage performed by the default
repository `EvaporatedRepository` looks something like this:

As long as calls to the remote storage don't return `Failure`:

* `EvaporatedRepository.write` writes to both local storage and remote storage
* `EvaporatedRepository.delete` deletes from both local storage and remote storage
* `EvaporatedRepository.clear` clears both local storage and remote storage
* `EvaporatedRepository.read` reads from remote storage

When any function call of the remote storage returns `Failure`, the repository switches into the
status `EvaporatedRepositoryStatus.syncRequired`. The repository will stay in this status until the
next application start. While in this status:

* `EvaporatedRepository.write` writes to local storage
* `EvaporatedRepository.delete` deletes from local storage
* `EvaporatedRepository.clear` clears local storage
* `EvaporatedRepository.read` reads from local storage

The status of the repository is persisted in the local storage.
When `EvaporatedRepository.initialize` is called (aka. on app start) and the repository's status
is `EvaporatedRepositoryStatus.syncRequired`, all changes that have been made to the local storage
during the last application runtime are pushed to the remote storage.

## Dart Versions

- Dart 3: >= 3.0.0

## Maintainers

- [Max Luchterhand](https://github.com/maxluchterhand1)
- [Max Luchterhand](https://github.com/crazy-rodney1)
