part of 'login_navigation_cubit.dart';

sealed class LoginNavigationState {}

class LoginNavigationStateLoggedIn implements LoginNavigationState {
  const LoginNavigationStateLoggedIn();
}

class LoginNavigationStateLoggedOut implements LoginNavigationState {
  const LoginNavigationStateLoggedOut();
}
