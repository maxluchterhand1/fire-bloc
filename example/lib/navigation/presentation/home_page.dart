import 'package:evaporated_storage_example/counter/presentation/counter_page.dart';
import 'package:evaporated_storage_example/form/presentation/form_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_index) {
        0 => const CounterPage(),
        _ => const FormPage(),
      },
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) => setState(() => _index = index),
        currentIndex: _index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.numbers),
            label: 'Counter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_format),
            label: 'Form',
          ),
        ],
      ),
    );
  }
}
