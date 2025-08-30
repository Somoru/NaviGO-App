import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/building.dart';
import '../models/node.dart';

class LocationTrackingService {
  // Sensor data streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Current state
  Offset _currentPosition = Offset.zero;
  double _currentHeading = 0; // in radians
  bool _isTracking = false;
  int _currentFloor = 1;
  
  // Step detection parameters
  final double _stepThreshold = 10.0; // Minimum acceleration to register as a step
  final double _stepLength = 0.65; // Average step length in meters
  final double _pixelsPerMeter = 50; // Conversion from meters to pixels on our map
  
  // Calibration parameters
  final double _smoothingFactor = 0.3; // For sensor data smoothing
  Vector3 _gravityCurrent = Vector3(0, 0, 0);
  
  // Last known measurements
  double _lastAccelMagnitude = 0;
  bool _isStepDetected = false;
  
  // Public getters
  Offset get currentPosition => _currentPosition;
  double get currentHeading => _currentHeading;
  int get currentFloor => _currentFloor;
  bool get isTracking => _isTracking;
  
  // Callbacks
  Function(Offset position, int floor)? onPositionChanged;
  
  // Initialize and request permissions
  Future<bool> initialize() async {
    // Request sensor permissions
    var status = await Permission.sensors.request();
    if (status != PermissionStatus.granted) {
      debugPrint('Sensor permission denied');
      return false;
    }
    return true;
  }
  
  // Set initial position (for calibration)
  void setInitialPosition(Offset position, int floor) {
    _currentPosition = position;
    _currentFloor = floor;
    debugPrint('Initial position set: $_currentPosition on floor $_currentFloor');
  }
  
  // Start tracking
  void startTracking() {
    if (_isTracking) return;
    
    _isTracking = true;
    
    // Start listening to accelerometer
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      _processAccelerometerData(event);
    });
    
    // Start listening to gyroscope
    _gyroscopeSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      _processGyroscopeData(event);
    });
    
    debugPrint('Location tracking started');
  }
  
  // Stop tracking
  void stopTracking() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _isTracking = false;
    debugPrint('Location tracking stopped');
  }
  
  // Process accelerometer data for step detection
  void _processAccelerometerData(AccelerometerEvent event) {
    // Apply low-pass filter to separate gravity from user acceleration
    _gravityCurrent = Vector3(
      _gravityCurrent.x + _smoothingFactor * (event.x - _gravityCurrent.x),
      _gravityCurrent.y + _smoothingFactor * (event.y - _gravityCurrent.y),
      _gravityCurrent.z + _smoothingFactor * (event.z - _gravityCurrent.z),
    );
    
    // Calculate user acceleration by removing gravity
    Vector3 userAcceleration = Vector3(
      event.x - _gravityCurrent.x,
      event.y - _gravityCurrent.y,
      event.z - _gravityCurrent.z,
    );
    
    // Calculate magnitude of acceleration
    double accelMagnitude = userAcceleration.length;
    
    // Step detection logic
    if (accelMagnitude > _stepThreshold && _lastAccelMagnitude <= _stepThreshold && !_isStepDetected) {
      _isStepDetected = true;
      _onStepDetected();
    } else if (accelMagnitude <= _stepThreshold && _lastAccelMagnitude > _stepThreshold) {
      _isStepDetected = false;
    }
    
    _lastAccelMagnitude = accelMagnitude;
  }
  
  // Process gyroscope data for heading
  void _processGyroscopeData(GyroscopeEvent event) {
    // Update heading based on gyroscope data (rotation around z-axis)
    // This is a simple integration approach and will drift over time
    _currentHeading += event.z * 0.02; // Assuming 50Hz sample rate
    
    // Normalize heading to [0, 2π)
    _currentHeading = _currentHeading % (2 * pi);
  }
  
  // Handle step detection
  void _onStepDetected() {
    // Calculate step distance in pixels
    double stepPixels = _stepLength * _pixelsPerMeter;
    
    // Calculate new position based on heading and step length
    double dx = stepPixels * cos(_currentHeading);
    double dy = stepPixels * sin(_currentHeading);
    
    // Update position
    _currentPosition = Offset(
      _currentPosition.dx + dx,
      _currentPosition.dy + dy,
    );
    
    // Notify listeners
    final callback = onPositionChanged;
    if (callback != null) {
      callback(_currentPosition, _currentFloor);
    }
  }
  
  // Find the closest node to current position
  String? findClosestNode(Building building) {
    if (building.floors.isEmpty) return null;
    
    // Find the current floor
    Floor? floor;
    try {
      floor = building.floors.firstWhere((f) => f.number == _currentFloor);
    } catch (e) {
      if (building.floors.isNotEmpty) {
        floor = building.floors.first;
      } else {
        return null;
      }
    }
    
    // Find closest node on the current floor
    Node? closestNode;
    double closestDistance = double.infinity;
    
    // Since we've already handled the null case above, floor is non-null here
    
    for (var node in floor.nodes) {
      double distance = (node.position - _currentPosition).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closestNode = node;
      }
    }
    
    return closestNode?.id;
  }
  
  // For testing: simulate a movement
  void simulateMovement(Offset movement, {int? newFloor}) {
    _currentPosition += movement;
    if (newFloor != null) {
      _currentFloor = newFloor;
    }
    
    // Notify listeners
    if (onPositionChanged != null) {
      onPositionChanged!(_currentPosition, _currentFloor);
    }
  }
  
  // Detect floor change (would use barometer or beacons in a real app)
  void detectFloorChange(int newFloor) {
    if (_currentFloor != newFloor) {
      _currentFloor = newFloor;
      if (onPositionChanged != null) {
        onPositionChanged!(_currentPosition, _currentFloor);
      }
    }
  }
}
