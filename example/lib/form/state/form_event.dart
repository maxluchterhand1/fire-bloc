part of 'form_bloc.dart';

sealed class FormEvent {}

class FormEventSetName implements FormEvent {
  const FormEventSetName(this.value);

  final String value;
}

class FormEventSetDateOfBirth implements FormEvent {
  const FormEventSetDateOfBirth(this.value);

  final DateTime value;
}

class FormEventSetCool implements FormEvent {
  const FormEventSetCool(this.value);

  final bool value;
}
