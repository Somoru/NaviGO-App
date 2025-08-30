import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'node.dart';

class Building {
  final String id;
  final String name;
  final List<Floor> floors;

  Building({
    String? id,
    required this.name,
    required this.floors,
  }) : id = id ?? const Uuid().v4();

  /// Convert Building to Map for storing in local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'floors': floors.map((floor) => floor.toMap()).toList(),
    };
  }

  /// Create a Building from a Map (retrieved from local storage)
  factory Building.fromMap(Map<String, dynamic> map) {
    return Building(
      id: map['id'],
      name: map['name'],
      floors: (map['floors'] as List)
          .map((floorMap) => Floor.fromMap(floorMap))
          .toList(),
    );
  }
}

class Floor {
  final String id;
  final int number;
  final String name;
  final List<Node> nodes;
  final Size size; // Size of the floor map

  Floor({
    String? id,
    required this.number,
    required this.name,
    required this.nodes,
    required this.size,
  }) : id = id ?? const Uuid().v4();

  /// Convert Floor to Map for storing in local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'nodes': nodes.map((node) => node.toMap()).toList(),
      'width': size.width,
      'height': size.height,
    };
  }

  /// Create a Floor from a Map (retrieved from local storage)
  factory Floor.fromMap(Map<String, dynamic> map) {
    return Floor(
      id: map['id'],
      number: map['number'],
      name: map['name'],
      nodes: (map['nodes'] as List)
          .map((nodeMap) => Node.fromMap(nodeMap))
          .toList(),
      size: Size(map['width'], map['height']),
    );
  }

  /// Get nodes on this floor
  List<Node> getNodesOnFloor() {
    return nodes.where((node) => node.floor == number).toList();
  }

  /// Get node by ID
  Node? getNodeById(String id) {
    try {
      return nodes.firstWhere((node) => node.id == id);
    } catch (e) {
      return null;
    }
  }
}
