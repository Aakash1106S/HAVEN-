import 'package:flutter/material.dart';

class ApplianceDetailScreen extends StatelessWidget {
  const ApplianceDetailScreen({
    super.key,
    required this.roomId,
    required this.channelId,
  });

  final String roomId;
  final String channelId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Appliance $channelId')),
      body: Center(
        child: Text('Appliance Detail: Room $roomId - Channel $channelId'),
      ),
    );
  }
}
