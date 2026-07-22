/*
  detailed_stats_screen.dart
  Detailed view for a selected statistic (e.g., per-workout breakdown,
  charts and lists). This file contains UI and presentation logic for
  drilling into aggregated statistics.
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitquest/core/services/databse_service.dart';
import 'package:fl_chart/fl_chart.dart';

class DetailedStatsScreen extends StatefulWidget {
  const DetailedStatsScreen({Key? key}) : super(key: key);

  @override
  State<DetailedStatsScreen> createState() => _DetailedStatsScreenState();
}

class _DetailedStatsScreenState extends State<DetailedStatsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _workouts = [];
  bool _loading = true;
  String _error = '';

  String _selectedType = 'All';
  DateTimeRange? _range;
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _range = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _db.getUserWorkouts();
      setState(() {
        _workouts = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredWorkouts {
    final start = _range?.start;
    final end = _range?.end;
    var list = _workouts.where((w) {
      final DateTime? ts =
          w['timestamp'] is DateTime ? w['timestamp'] as DateTime : null;
      if (start != null && end != null && ts != null) {
        if (ts.isBefore(start) || ts.isAfter(end)) return false;
      }
      if (_selectedType != 'All' && (w['type'] ?? '') != _selectedType)
        return false;
      return true;
    }).toList();

    if (_sortBy == 'newest') {
      list.sort((a, b) {
        final da = a['timestamp'] as DateTime?;
        final db = b['timestamp'] as DateTime?;
        return (db ?? DateTime(0)).compareTo(da ?? DateTime(0));
      });
    } else if (_sortBy == 'oldest') {
      list.sort((a, b) {
        final da = a['timestamp'] as DateTime?;
        final db = b['timestamp'] as DateTime?;
        return (da ?? DateTime(0)).compareTo(db ?? DateTime(0));
      });
    } else if (_sortBy == 'distance') {
      list.sort((a, b) => (b['distance'] ?? 0).compareTo(a['distance'] ?? 0));
    }

    return list;
  }

  List<DateTime> _getDaysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(DateTime(end.year, end.month, end.day));
        d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return days;
  }

  Map<DateTime, double> _aggregateDistanceByDay(
      List<Map<String, dynamic>> workouts, DateTime start, DateTime end) {
    final map = <DateTime, double>{};
    for (final d in _getDaysInRange(start, end)) {
      map[d] = 0.0;
    }
    for (final w in workouts) {
      final ts = w['timestamp'] as DateTime?;
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      if (day.isBefore(DateTime(start.year, start.month, start.day)) ||
          day.isAfter(DateTime(end.year, end.month, end.day))) continue;
      map[day] = (map[day] ?? 0) + ((w['distance'] ?? 0) as num).toDouble();
    }
    return map;
  }

  Map<DateTime, double> _aggregateCaloriesByDay(
      List<Map<String, dynamic>> workouts, DateTime start, DateTime end) {
    final map = <DateTime, double>{};
    for (final d in _getDaysInRange(start, end)) {
      map[d] = 0.0;
    }
    for (final w in workouts) {
      final ts = w['timestamp'] as DateTime?;
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      if (day.isBefore(DateTime(start.year, start.month, start.day)) ||
          day.isAfter(DateTime(end.year, end.month, end.day))) continue;
      map[day] = (map[day] ?? 0) + ((w['calories'] ?? 0) as num).toDouble();
    }
    return map;
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        _range = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = <String>{'All'};
    for (final w in _workouts) {
      final t = (w['type'] ?? 'Workout').toString();
      types.add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Stats'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('Error: $_error'))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Filters
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedType,
                              items: types
                                  .map((t) => DropdownMenuItem(
                                      value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedType = v ?? 'All'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _pickRange,
                            child: Text(
                                '${DateFormat.yMd().format(_range!.start)} - ${DateFormat.yMd().format(_range!.end)}'),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(
                                  value: 'newest', child: Text('Newest')),
                              DropdownMenuItem(
                                  value: 'oldest', child: Text('Oldest')),
                              DropdownMenuItem(
                                  value: 'distance', child: Text('Distance')),
                            ],
                            onChanged: (v) =>
                                setState(() => _sortBy = v ?? 'newest'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Charts
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Distance Over Time',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 200,
                                child: _buildDistanceChart(),
                              ),
                              const SizedBox(height: 16),
                              const Text('Calories Over Time',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 200,
                                child: _buildCaloriesChart(),
                              ),
                              const SizedBox(height: 16),
                              const Text('Workouts',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredWorkouts.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final w = _filteredWorkouts[index];
                                  final ts = w['timestamp'] as DateTime?;
                                  final timeStr = ts != null
                                      ? DateFormat.yMMMd().add_jm().format(ts)
                                      : 'Unknown';
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                          w['type']?.toString() ?? 'Workout'),
                                      subtitle: Text(timeStr),
                                      trailing: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text('${w['distance'] ?? 0} km'),
                                          Text('${w['calories'] ?? 0} kcal'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDistanceChart() {
    final filtered = _filteredWorkouts;
    final start = _range!.start;
    final end = _range!.end;
    final map = _aggregateDistanceByDay(filtered, start, end);
    final days = map.keys.toList()..sort();
    final max = map.values.fold<double>(0, (p, e) => p > e ? p : e);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= days.length)
                        return const SizedBox.shrink();
                      return Center(
                          child: Text(DateFormat.Md().format(days[idx])));
                    })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          ),
          gridData: FlGridData(show: false),
          barGroups: List.generate(days.length, (i) {
            final val = map[days[i]] ?? 0.0;
            return BarChartGroupData(
                x: i,
                barRods: [BarChartRodData(toY: val, color: Colors.blueAccent)]);
          }),
          maxY: (max <= 0) ? 1 : (max * 1.2),
        ),
      ),
    );
  }

  Widget _buildCaloriesChart() {
    final filtered = _filteredWorkouts;
    final start = _range!.start;
    final end = _range!.end;
    final map = _aggregateCaloriesByDay(filtered, start, end);
    final days = map.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      spots.add(FlSpot(i.toDouble(), map[days[i]] ?? 0.0));
    }

    final max = map.values.fold<double>(0, (p, e) => p > e ? p : e);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.orange,
                barWidth: 2,
                dotData: FlDotData(show: false)),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= days.length)
                        return const SizedBox.shrink();
                      return Center(
                          child: Text(DateFormat.Md().format(days[idx])));
                    })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          ),
          gridData: FlGridData(show: false),
          minY: 0,
          maxY: (max <= 0) ? 1 : (max * 1.2),
        ),
      ),
    );
  }

  // helper removed — chips are created inline now
}
