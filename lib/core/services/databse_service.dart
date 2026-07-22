/*
  databse_service.dart
  Abstraction over Firestore for reading and writing user data such as
  workouts, goals and profile. Uses `AuthService` to scope documents to
  the currently signed-in user.
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitquest/core/services/auth_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  Future<void> saveWorkout({
    required String type,
    required int duration,
    required double distance,
    required int calories,
    required int averageHeartRate,
    List<Map<String, dynamic>>? routePoints,
  }) async {
    final user = await _auth.currentUser;
    if (user == null) return;

    final workoutData = {
      'type': type,
      'duration': duration,
      'distance': distance,
      'calories': calories,
      'averageHeartRate': averageHeartRate,
      'timestamp': FieldValue.serverTimestamp(),
      'routePoints': routePoints ?? [],
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .add(workoutData);
  }

  Future<List<Map<String, dynamic>>> getUserWorkouts() async {
    final user = await _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'timestamp': (data['timestamp'] as Timestamp).toDate(),
      };
    }).toList();
  }

  Future<void> saveUserGoals(Map<String, dynamic> goals) async {
    final user = await _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({'goals': goals}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getUserGoals() async {
    final user = await _auth.currentUser;
    if (user == null) return {};

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return (doc.data()?['goals'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    final user = await _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({'profile': profileData}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final user = await _auth.currentUser;
    if (user == null) return {};

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return (doc.data()?['profile'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final workouts = await getUserWorkouts();

    if (workouts.isEmpty) {
      return {
        'totalWorkouts': 0,
        'totalDistance': 0,
        'totalCalories': 0,
        'totalDuration': 0,
        'averageHeartRate': 0,
      };
    }

    final totalWorkouts = workouts.length;
    final totalDistance = workouts.fold<double>(
        0, (sum, workout) => sum + (workout['distance'] as num).toDouble());
    final totalCalories = workouts.fold<int>(
        0, (sum, workout) => sum + (workout['calories'] as num).toInt());
    final totalDuration = workouts.fold<int>(
        0, (sum, workout) => sum + (workout['duration'] as num).toInt());
    final averageHeartRate = workouts.fold<int>(
            0,
            (sum, workout) =>
                sum + (workout['averageHeartRate'] as num).toInt()) ~/
        totalWorkouts;

    return {
      'totalWorkouts': totalWorkouts,
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'totalDuration': totalDuration,
      'averageHeartRate': averageHeartRate,
    };
  }

  /// Creates a new workout document in an "in_progress" state and returns its id.
  Future<String?> createWorkoutInProgress({
    String type = 'Workout',
    int duration = 0,
    double distance = 0.0,
    int calories = 0,
    int averageHeartRate = 0,
  }) async {
    final user = await _auth.currentUser;
    if (user == null) return null;

    final workoutData = {
      'type': type,
      'duration': duration,
      'distance': distance,
      'calories': calories,
      'averageHeartRate': averageHeartRate,
      'status': 'in_progress',
      'timestamp': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .add(workoutData);

    return docRef.id;
  }

  /// Update an existing workout document by id with the provided fields.
  Future<void> updateWorkout(
      String workoutId, Map<String, dynamic> fields) async {
    final user = await _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .doc(workoutId)
        .set(fields, SetOptions(merge: true));
  }
}
