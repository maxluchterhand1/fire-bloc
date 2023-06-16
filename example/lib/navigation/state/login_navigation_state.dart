part of 'login_navigation_cubit.dart';

sealed class LoginNavigationState {}

class LoginNavigationStateLoggedIn extends Equatable
    implements LoginNavigationState {
  const LoginNavigationStateLoggedIn();

  @override
  List<Object?> get props => [];
}

class LoginNavigationStateLoggedOut extends Equatable
    implements LoginNavigationState {
  const LoginNavigationStateLoggedOut();

  @override
  List<Object?> get props => [];
}
