import 'package:fire_bloc/fire_bloc.dart';

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
  Option<int> fromJson(Map<String, dynamic> json) => switch (json['value']) {
        final int value => Some(value),
        _ => const None(),
      };

  @override
  Map<String, dynamic> toJson(int state) => {'value': state};
}
