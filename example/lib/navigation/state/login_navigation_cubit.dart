import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

part 'login_navigation_state.dart';

class LoginNavigationCubit extends Cubit<LoginNavigationState> {
  LoginNavigationCubit({required fb_auth.FirebaseAuth auth})
      : _auth = auth,
        super(const LoginNavigationStateLoggedOut()) {
    _setupSubscription();
  }

  final fb_auth.FirebaseAuth _auth;

  StreamSubscription<fb_auth.User?>? _fbAuthSubscription;

  void _setupSubscription() {
    _fbAuthSubscription = _auth.idTokenChanges().listen((fb_auth.User? user) {
      if (isClosed) return;
      if (user != null) {
        emit(const LoginNavigationStateLoggedIn());
      } else {
        emit(const LoginNavigationStateLoggedOut());
      }
    });
  }

  @override
  Future<void> close() async {
    await _fbAuthSubscription?.cancel();
    await super.close();
  }
}
