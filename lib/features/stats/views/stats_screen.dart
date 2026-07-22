/*
  stats_screen.dart
  High-level statistics screen that shows summary metrics for the user
  (distance, calories, workouts). Uses services to load aggregated data.
*/

import 'package:flutter/material.dart';
import 'detailed_stats_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 100, color: Colors.blue[300]),
            const SizedBox(height: 20),
            const Text(
              'Statistics Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your workout statistics will appear here',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DetailedStatsScreen()),
                );
              },
              child: const Text('View Detailed Stats'),
            ),
          ],
        ),
      ),
    );
  }
}
