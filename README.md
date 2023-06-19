## fire_bloc: An Extension to Bloc for State Persistence

An extension to [package:bloc](https://github.com/felangel/bloc) which automatically persists and
restores bloc and cubit states locally and remotely (Firestore by default). Built to work
with [package:bloc](https://pub.dev/packages/bloc). Heavily inspired
by [package:hydrated_bloc](https://pub.dev/packages/hydrated_bloc).

This package aims to streamline the state management for applications that require robust and  
consistent state persistence across sessions and devices.

**Learn more at [bloclibrary.dev](https://bloclibrary.dev)!**
  
---  

## Features and Working Principle

### Features

* Works with any storage provider via the `EvaporatedStorage` interface.
* Comes with out-of-the-box implementations: `FirestoreEvaporatedStorage`  
  and `HiveEvaporatedStorage`.
* Provides automatic synchronization between local and remote storage.
* Supports Firebase Authentication for user-specific state management.

### Working Principle

The package operates by mediating between local and remote storage through  
the `EvaporatedRepository` (which also implements `EvaporatedStorage`).

`HiveEvaporatedStorage` is built on top of [hive](https://pub.dev/packages/hive) for
platform-agnostic and performant storage.

The state of `FireBloc` and `FireCubit` is wrapped by a sealed class `Option` to account for the  
asynchronous nature of network-based state loading.

To accommodate individual project requirements, you can customize the mediation logic by creating  
your own repository and assigning that to `EvaporatedRepository.instance`.
  
---  

## Usage

### Setup

Your project should be connected to a Firebase project that uses Firestore and Authentication to  
facilitate user-specific state management and
persistence. [Click here](https://firebase.google.com/docs/flutter/setup) for more information on
setting up Firebase.

You need to setup your Firestore rules in such a way that each user can read from and write to their
own collection:

``` rules_version = '2';    
service cloud.firestore {    
    match /databases/{database}/documents {    
        // Each user can read and write documents in their own collection.    
        match /{userId}/{document=**} {    
            allow read, write: if request.auth != null && request.auth.uid == userId;    
        }    
    }    
}    
```  

In your main function, set up the storage for `FireBloc` and `FireCubit`. Here's how:

```dart  
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        break;
      case None():
        break;
    }
  }

  @override int? fromJson(Map<String, dynamic> json) =>
      switch (json['value']) {
        final int value => value, _ => null
      };

  @override Map<String, dynamic>? toJson(int state) => {'value': state};
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
              break;
          }
          break;
        case None():
          break;
      }
    });
  }

  @override int? fromJson(Map<String, dynamic> json) =>
      switch (json['value']) {
        final int value => value, _ => null
      };

  @override Map<String, dynamic>? toJson(int state) => {'value': state};
}  
```  

Now the `CounterCubit` and `CounterBloc` will automatically persist/restore their state. We can  
increment the counter value, hot restart, kill the app, etc... and the previous state will be  
retained. We can also start the app on a different device or reinstall the app, and the state will  
still be available.

  
---  

## Local and Remote Mediation

The package's default `EvaporatedRepository` manages local and remote storage as follows:

* While remote storage is accessible, all `write`, `delete`, and `clear` operations are performed
  on both local and remote storage.
* If any remote storage function call fails, the repository switches  
  to `EvaporatedRepositoryStatus.syncRequired` and subsequently performs all operations locally.
* Upon application restart, if the repository's status is `EvaporatedRepositoryStatus.syncRequired`,
  the repository syncs local changes with the remote storage.

---  

## Dart Versions

- Dart 3: >= 3.0.0

---  

## Contribution Guidelines

Contributions to improve this package are welcome. Feel free to fork the repo, make your changes,  
and open a pull request. Please ensure your changes pass the existing tests and include new tests  
for added features or functionality.

## Maintainers

- [Max Luchterhand](https://github.com/maxluchterhand1) ([alt](https://github.com/crazy-rodney))
  
