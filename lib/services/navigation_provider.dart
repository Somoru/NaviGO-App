import 'package:flutter/material.dart';
import '../models/building.dart';
import '../models/navigation.dart';
import '../services/navigation_service.dart';

class NavigationProvider extends ChangeNotifier {
  Building? _building;
  int _currentFloorIndex = 0;
  String? _selectedNodeId;
  String? _destinationNodeId;
  NavigationRoute? _currentRoute;
  final NavigationService _navigationService = NavigationService();

  // Getters
  Building? get building => _building;
  int get currentFloorIndex => _currentFloorIndex;
  Floor? get currentFloor => _building?.floors[_currentFloorIndex];
  String? get selectedNodeId => _selectedNodeId;
  String? get destinationNodeId => _destinationNodeId;
  NavigationRoute? get currentRoute => _currentRoute;
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
