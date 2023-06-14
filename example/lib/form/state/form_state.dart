part of 'form_bloc.dart';

@immutable
class FormBlocState extends Equatable {
  const FormBlocState({
    required this.name,
    required this.dateOfBirth,
    required this.isCool,
  });

  factory FormBlocState.fromJson(Map<String, dynamic> json) => switch (json) {
        {
          'name': final String name,
          'date_of_birth': final String dateOfBirth,
          'is_cool': final bool isCool,
        } =>
          FormBlocState(
            name: name,
            dateOfBirth: DateTime.parse(dateOfBirth),
            isCool: isCool,
          ),
        _ => () {
            assert(false, 'Invalid json passed to FormState.fromJson');
            return empty;
          }(),
      };

  static final empty = FormBlocState(
    name: '',
    dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 20)),
    isCool: true,
  );

  final String name;

  final DateTime dateOfBirth;

  final bool isCool;

  FormBlocState copyWith({
    String? name,
    DateTime? dateOfBirth,
    bool? isCool,
  }) =>
      FormBlocState(
        name: name ?? this.name,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        isCool: isCool ?? this.isCool,
      );

  @override
  List<Object> get props => [
        name,
        dateOfBirth,
        isCool,
      ];

  Map<String, dynamic> toJson() => {
        'name': name,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'is_cool': isCool,
      };
}
