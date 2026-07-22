/*
  workout_viewmodel.dart
  ViewModel for workout tracking flows. Contains workout state, timers and
  business logic used by workout UI screens.
*/

import 'dart:async';
import 'package:flutter/material.dart';

class WorkoutViewModel extends ChangeNotifier {
  bool _isTracking = false;
  int _elapsedSeconds = 0;
  double _distanceKm = 0.0;
  int _heartRate = 72;
  int _calories = 0;
  List<int> _heartRateHistory = List.generate(20, (index) => 72);
  Timer? _timer;
  Timer? _heartRateTimer;
  DateTime? _startTime;

  bool get isTracking => _isTracking;
  int get elapsedSeconds => _elapsedSeconds;
  double get distanceKm => _distanceKm;
  int get heartRate => _heartRate;
  int get calories => _calories;
  List<int> get heartRateHistory => _heartRateHistory;

  double get pace => _elapsedSeconds > 0 && _distanceKm > 0
      ? (_elapsedSeconds / 60) / _distanceKm
      : 0.0;

  WorkoutViewModel() {
    _initialize();
  }

  void _initialize() {
    _heartRateHistory = List.generate(20, (index) => 70 + (index % 10));
  }

  void toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
    notifyListeners();
  }

  void _startTracking() {
    _isTracking = true;
    _startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      if (_elapsedSeconds % 5 == 0) {
        _distanceKm += 0.01;
        _calories = (_distanceKm * 80).toInt();
      }
      notifyListeners();
    });

    _heartRateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final baseRate = 70;
      final workoutEffect = (_elapsedSeconds ~/ 60) * 2;
      final randomVariation = (DateTime.now().millisecond % 20) - 10;

      _heartRate = baseRate + workoutEffect + randomVariation;
      _heartRate = _heartRate.clamp(60, 180);

      _heartRateHistory.add(_heartRate);
      if (_heartRateHistory.length > 50) {
        _heartRateHistory.removeAt(0);
      }
      notifyListeners();
    });
  }

  void _stopTracking() {
    _isTracking = false;
    _timer?.cancel();
    _heartRateTimer?.cancel();
  }

  void reset() {
    _stopTracking();
    _elapsedSeconds = 0;
    _distanceKm = 0.0;
    _heartRate = 72;
    _calories = 0;
    _heartRateHistory = List.generate(20, (index) => 72);
    notifyListeners();
  }

  Future<void> saveWorkout() async {
    _stopTracking();

    final workoutData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'duration': _elapsedSeconds,
      'distance': _distanceKm,
      'calories': _calories,
      'averageHeartRate': _calculateAverageHeartRate(),
      'type': 'Running',
    };

    print('Workout saved: $workoutData');

    reset();
  }

  int _calculateAverageHeartRate() {
    if (_heartRateHistory.isEmpty) return 72;
    final sum = _heartRateHistory.reduce((a, b) => a + b);
    return sum ~/ _heartRateHistory.length;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heartRateTimer?.cancel();
    super.dispose();
  }
}
