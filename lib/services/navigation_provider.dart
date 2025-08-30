import 'package:flutter/material.dart';
import '../models/building.dart';
import '../models/navigation.dart';
import '../models/node.dart';
import '../services/navigation_service.dart';
import '../services/location_tracking_service.dart';

class NavigationProvider extends ChangeNotifier {
  Building? _building;
  int _currentFloorIndex = 0;
  String? _selectedNodeId;
  String? _destinationNodeId;
  NavigationRoute? _currentRoute;
  final NavigationService _navigationService = NavigationService();
  final LocationTrackingService _locationService = LocationTrackingService();
  
  bool _isUsingAutoTracking = false;
  bool _isTrackingInitialized = false;

  // Getters
  Building? get building => _building;
  int get currentFloorIndex => _currentFloorIndex;
  Floor? get currentFloor => _building?.floors[_currentFloorIndex];
  String? get selectedNodeId => _selectedNodeId;
  String? get destinationNodeId => _destinationNodeId;
  NavigationRoute? get currentRoute => _currentRoute;
  bool get isUsingAutoTracking => _isUsingAutoTracking;
  bool get isTrackingInitialized => _isTrackingInitialized;
  LocationTrackingService get locationService => _locationService;
  List<String> get pathNodeIdsOnCurrentFloor {
    if (_currentRoute == null || currentFloor == null) return [];
    if (_currentRoute!.pathNodeIds.isEmpty) return [];
    return _currentRoute!.pathNodeIds.where((nodeId) {
      final node = _findNodeById(nodeId);
      return node != null && node.floor == currentFloor!.number;
    }).toList();
  }

  // Methods
  void setBuilding(Building building) {
    _building = building;
    _currentFloorIndex = 0;
    _selectedNodeId = null;
    _destinationNodeId = null;
    _currentRoute = null;
    notifyListeners();
  }
  
  // Initialize location tracking
  Future<bool> initializeLocationTracking() async {
    bool success = await _locationService.initialize();
    if (success) {
      _isTrackingInitialized = true;
      
      // Set up callback for position updates
      _locationService.onPositionChanged = (position, floor) {
        if (_isUsingAutoTracking) {
          _handlePositionUpdate(position, floor);
        }
      };
      
      notifyListeners();
    }
    return success;
  }
  
  // Toggle automatic position tracking
  Future<bool> toggleAutoTracking() async {
    if (!_isTrackingInitialized) {
      bool initialized = await initializeLocationTracking();
      if (!initialized) return false;
    }
    
    _isUsingAutoTracking = !_isUsingAutoTracking;
    
    if (_isUsingAutoTracking) {
      // Start tracking
      _locationService.startTracking();
      
      // If we have a building and a selected node, use it for initial position
      if (_building != null && _selectedNodeId != null) {
        Node? node = _findNodeById(_selectedNodeId!);
        if (node != null) {
          _locationService.setInitialPosition(node.position, node.floor);
          
          // Update current floor to match
          _setCurrentFloorByNumber(node.floor);
        }
      }
    } else {
      // Stop tracking
      _locationService.stopTracking();
    }
    
    notifyListeners();
    return true;
  }
  
  // Handle updates from location service
  void _handlePositionUpdate(Offset position, int floor) {
    // Update the current floor if needed
    _setCurrentFloorByNumber(floor);
    
    // Find the closest node
    String? nodeId = _locationService.findClosestNode(_building!);
    if (nodeId != null) {
      bool needsRecalculation = false;
      
      // Check if user is off-route
      if (_currentRoute != null && _destinationNodeId != null) {
        // If current position is not on the route path, we should recalculate
        if (!_currentRoute!.pathNodeIds.contains(nodeId)) {
          // User has deviated from the path
          needsRecalculation = true;
        }
      }
      
      if (nodeId != _selectedNodeId || needsRecalculation) {
        // Update selected node
        _selectedNodeId = nodeId;
        
        // Recalculate route if destination is set
        if (_destinationNodeId != null) {
          calculateRoute();
        }
        
        notifyListeners();
      }
    }
  }
  
  // Set current floor by floor number instead of index
  void _setCurrentFloorByNumber(int floorNumber) {
    if (_building == null) return;
    
    int index = _building!.floors.indexWhere((floor) => floor.number == floorNumber);
    if (index >= 0 && index != _currentFloorIndex) {
      _currentFloorIndex = index;
      notifyListeners();
    }
  }

  void setCurrentFloorIndex(int index) {
    if (_building != null && index >= 0 && index < _building!.floors.length) {
      _currentFloorIndex = index;
      notifyListeners();
    }
  }

  void selectNode(String nodeId) {
    _selectedNodeId = nodeId;
    if (_destinationNodeId != null) {
      calculateRoute();
    }
    notifyListeners();
  }

  void selectDestination(String nodeId) {
    _destinationNodeId = nodeId;
    if (_selectedNodeId != null) {
      calculateRoute();
    }
    notifyListeners();
  }

  void calculateRoute() {
    if (_building == null ||
        _selectedNodeId == null ||
        _destinationNodeId == null) {
      _currentRoute = null;
      notifyListeners();
      return;
    }

    _currentRoute = _navigationService.findShortestPath(
        _building!, _selectedNodeId!, _destinationNodeId!);

    // If route includes multiple floors, set the current floor to the start floor
    if (_currentRoute != null && _currentRoute!.requiresFloorChange) {
      final startFloor = _currentRoute!.startFloor;
      final floorIndex =
          _building!.floors.indexWhere((floor) => floor.number == startFloor);
      if (floorIndex >= 0) {
        _currentFloorIndex = floorIndex;
      }
    }

    notifyListeners();
  }

  void clearRoute() {
    _selectedNodeId = null;
    _destinationNodeId = null;
    _currentRoute = null;
    notifyListeners();
  }

  // Helper method to find a node by ID
  _findNodeById(String nodeId) {
    if (_building == null) return null;

    for (var floor in _building!.floors) {
      for (var node in floor.nodes) {
        if (node.id == nodeId) {
          return node;
        }
      }
    }
    return null;
  }
}
