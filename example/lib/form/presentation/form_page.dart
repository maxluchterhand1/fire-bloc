import 'package:evaporated_storage_example/form/state/form_bloc.dart';
import 'package:fire_bloc/fire_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _nameController = TextEditingController();

  final _formBloc = FormBloc();

  @override
  void dispose() {
    _nameController.dispose();
    _formBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formBloc,
      child: BlocConsumer<FormBloc, Option<FormBlocState>>(
        listenWhen: (previous, next) => previous is None && next is Some,
        listener: (context, state) {
          setState(() {
            _nameController.text = (state as Some<FormBlocState>).value.name;
          });
        },
        builder: (context, state) {
          switch (state) {
            case None():
              return const Center(child: CircularProgressIndicator());
            case Some(value: final state):
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Name',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextField(
                          controller: _nameController,
                          onChanged: (value) => context
                              .read<FormBloc>()
                              .add(FormEventSetName(value)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Date of birth',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        CalendarDatePicker(
                          initialDate: state.dateOfBirth,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365 * 100)),
                          lastDate: DateTime.now(),
                          onDateChanged: (value) => context
                              .read<FormBloc>()
                              .add(FormEventSetDateOfBirth(value)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Text(
                          'Is cool',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 32),
                        Switch(
                          value: state.isCool,
                          onChanged: (value) => context
                              .read<FormBloc>()
                              .add(FormEventSetCool(value)),
                        ),
                      ],
                    )
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}
