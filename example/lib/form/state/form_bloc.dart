import 'package:equatable/equatable.dart';
import 'package:evaporated_storage/fire_bloc/domain/fire_bloc.dart';
import 'package:flutter/cupertino.dart';

part 'form_event.dart';

part 'form_state.dart';

class FormBloc extends FireBloc<FormEvent, FormBlocState> {
  FormBloc() : super(FireStateLoaded(FormBlocState.empty)) {
    fireOn<FormEvent>((event, fireEmit) {
      switch (state) {
        case FireStateLoaded(value: final innerState):
          switch (event) {
            case FormEventSetName(value: final value):
              fireEmit(innerState.copyWith(name: value));
            case FormEventSetDateOfBirth(value: final value):
              fireEmit(innerState.copyWith(dateOfBirth: value));
            case FormEventSetCool(value: final value):
              fireEmit(innerState.copyWith(isCool: value));
          }
        case FireStateLoading():
          break;
      }
    });
  }

  @override
  FormBlocState? fromJson(Map<String, dynamic> json) =>
      FormBlocState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(FormBlocState state) => state.toJson();
}
