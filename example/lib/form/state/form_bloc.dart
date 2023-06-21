import 'package:equatable/equatable.dart';
import 'package:fire_bloc/fire_bloc.dart';
import 'package:flutter/cupertino.dart';

part 'form_event.dart';

part 'form_state.dart';

class FormBloc extends FireBloc<FormEvent, FormBlocState> {
  FormBloc() : super(Some(FormBlocState.empty)) {
    fireOn<FormEvent>((event, fireEmit) {
      switch (state) {
        case Some(value: final innerState):
          switch (event) {
            case FormEventSetName(value: final value):
              fireEmit(innerState.copyWith(name: value));
            case FormEventSetDateOfBirth(value: final value):
              fireEmit(innerState.copyWith(dateOfBirth: value));
            case FormEventSetCool(value: final value):
              fireEmit(innerState.copyWith(isCool: value));
          }
        case None():
          break;
      }
    });
  }

  @override
  Some<FormBlocState> fromJson(Map<String, dynamic> json) =>
      Some(FormBlocState.fromJson(json));

  @override
  Map<String, dynamic> toJson(FormBlocState state) => state.toJson();
}
