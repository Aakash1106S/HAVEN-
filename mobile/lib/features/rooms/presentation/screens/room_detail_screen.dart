import 'package:flutter/material.dart';

class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({
    super.key,
    required this.roomId,
  });

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room $roomId')),
      body: Center(
        child: Text('Room Detail: $roomId'),
      ),
    );
  }
}
