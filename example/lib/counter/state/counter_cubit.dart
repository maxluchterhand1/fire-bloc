import 'package:evaporated_storage/evaporated_storage.dart';

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
  int? fromJson(Map<String, dynamic> json) => switch (json['value']) {
        final int value => value,
        _ => null,
      };

  @override
  Map<String, dynamic>? toJson(int state) => {'value': state};
}
