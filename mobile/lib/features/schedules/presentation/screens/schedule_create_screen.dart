import 'package:flutter/material.dart';

class ScheduleCreateScreen extends StatelessWidget {
  const ScheduleCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Schedule')),
      body: const Center(
        child: Text('Schedule Create Screen'),
      ),
    );
  }
}
