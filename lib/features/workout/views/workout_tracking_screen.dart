/*
  workout_tracking_screen.dart
  UI screen for tracking workouts (runs, cycles). Shows map, controls to
  start/stop sessions and displays live metrics; connects to workout viewmodel.
*/

import 'package:flutter/material.dart';
import 'package:fitquest/core/theme/app_theme.dart';
import 'dart:async';
import 'package:fitquest/core/services/databse_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

class WorkoutTrackingScreen extends StatefulWidget {
  final bool startImmediately;

  const WorkoutTrackingScreen({Key? key, this.startImmediately = false})
      : super(key: key);

  @override
  State<WorkoutTrackingScreen> createState() => _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends State<WorkoutTrackingScreen> {
  bool _isTracking = false;
  int _elapsedSeconds = 0;
  double _distanceKm = 0.0;
  int _heartRate = 72;
  Timer? _timer;
  String? _workoutId;
  StreamSubscription<Position>? _positionSub;
  final List<ll.LatLng> _routePoints = [];
  ll.LatLng? _currentCenter;

  @override
  void dispose() {
    _timer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.startImmediately) {
      // Delay slightly to ensure the widget is mounted and rendered.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isTracking) {
          _startTracking();
        }
      });
    }
  }

  Future<void> _startTracking() async {
    setState(() {
      _isTracking = true;
    });
    final ok = await _ensureLocationPermission();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permission required to track workouts.')));
      setState(() {
        _isTracking = false;
      });
      return;
    }
    // Create an in-progress workout document if not already created
    if (_workoutId == null) {
      DatabaseService()
          .createWorkoutInProgress(
        type: 'Run',
        duration: 0,
        distance: 0.0,
        calories: 0,
        averageHeartRate: _heartRate,
      )
          .then((id) {
        setState(() {
          _workoutId = id;
        });
      }).catchError((_) {
        // ignore errors for now
      });
    }
    // start listening to location updates
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          distanceFilter: 5, accuracy: LocationAccuracy.best),
    ).listen((pos) {
      final newPoint = ll.LatLng(pos.latitude, pos.longitude);
      setState(() {
        if (_currentCenter == null) _currentCenter = newPoint;
        if (_routePoints.isNotEmpty) {
          final prev = _routePoints.last;
          final meters = Geolocator.distanceBetween(prev.latitude,
              prev.longitude, newPoint.latitude, newPoint.longitude);
          _distanceKm += meters / 1000.0;
        }
        _routePoints.add(newPoint);
        _currentCenter = newPoint;
      });
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds % 5 == 0) {
          _distanceKm += 0.01;
        }
        _heartRate = 70 +
            (_elapsedSeconds ~/ 60) * 2 +
            (DateTime.now().millisecond % 20) -
            10;
        if (_heartRate > 180) _heartRate = 180;
        if (_heartRate < 60) _heartRate = 60;
      });
    });
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });
    _timer?.cancel();
    _positionSub?.cancel();
    // update workout doc to mark completed
    if (_workoutId != null) {
      final minutes = (_elapsedSeconds / 60).round();
      DatabaseService().updateWorkout(_workoutId!, {
        'status': 'completed',
        'duration': minutes,
        'distance': double.parse(_distanceKm.toStringAsFixed(2)),
        'calories': (_distanceKm * 50).round(),
        'averageHeartRate': _heartRate,
        'timestamp': FieldValue.serverTimestamp(),
        'routePoints': _routePoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      });
    }
  }

  void _reset() {
    setState(() {
      _elapsedSeconds = 0;
      _distanceKm = 0.0;
      _heartRate = 72;
      _routePoints.clear();
      _workoutId = null;
    });
    _timer?.cancel();
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  _formatTime(_elapsedSeconds),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.terrain,
                      value: '${_distanceKm.toStringAsFixed(2)} km',
                      label: 'Distance',
                    ),
                    _buildStatItem(
                      icon: Icons.speed,
                      value:
                          '${(_elapsedSeconds > 0 && _distanceKm > 0 ? (_elapsedSeconds / 60) / _distanceKm : 0).toStringAsFixed(1)} min/km',
                      label: 'Pace',
                    ),
                    _buildStatItem(
                      icon: Icons.favorite,
                      value: '$_heartRate BPM',
                      label: 'Heart Rate',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Map preview showing route (flutter_map v8 API)
                SizedBox(
                  height: 220,
                  child: _currentCenter == null && _routePoints.isEmpty
                      ? Center(
                          child: Text(
                            'Map will appear when tracking starts',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: _currentCenter ??
                                (_routePoints.isNotEmpty
                                    ? _routePoints.last
                                    : ll.LatLng(0, 0)),
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            if (_routePoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePoints,
                                    color: Colors.blueAccent,
                                    strokeWidth: 4.0,
                                  ),
                                ],
                                cullingMargin: 10,
                              ),
                            MarkerLayer(
                              markers: _currentCenter != null
                                  ? [
                                      Marker(
                                        width: 40,
                                        height: 40,
                                        point: _currentCenter!,
                                        child: const Icon(Icons.my_location,
                                            color: Colors.blue),
                                      ),
                                    ]
                                  : [],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.backgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.replay,
                        label: 'Reset',
                        onPressed: _reset,
                        color: Colors.grey,
                      ),
                      _buildControlButton(
                        icon: _isTracking ? Icons.pause : Icons.play_arrow,
                        label: _isTracking ? 'Pause' : 'Start',
                        onPressed: _isTracking ? _stopTracking : _startTracking,
                        color:
                            _isTracking ? Colors.orange : AppTheme.primaryColor,
                        isLarge: true,
                      ),
                      _buildControlButton(
                        icon: Icons.save,
                        label: 'Save',
                        onPressed: () {
                          // Save workout
                          _stopTracking();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Workout saved!')),
                          );
                        },
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isLarge = false,
  }) {
    return Column(
      children: [
        Container(
          width: isLarge ? 70 : 56,
          height: isLarge ? 70 : 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: isLarge ? 32 : 24),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
