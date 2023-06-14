import 'package:evaporated_storage/fire_bloc/domain/fire_bloc.dart';

class CounterCubit extends FireCubit<int> {
  CounterCubit() : super(FireStateLoaded(0));

  void increment() {
    switch (state) {
      case FireStateLoaded(value: final value):
        fire(value + 1);
      case FireStateLoading():
    }
  }

  @override
  int? fromJson(Map<String, dynamic> json) => switch (json['value']) {
        final int value => value,
        _ => null,
      };

  @override
  Map<String, dynamic>? toJson(int state) => {'value': state};
}
