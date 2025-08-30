import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Node {
  final String id;
  final String name;
  final Offset position;
  final int floor;
  final NodeType type;
  final Map<String, double> connections; // Map of nodeId to distance

  Node({
    String? id,
    required this.name,
    required this.position,
    required this.floor,
    required this.type,
    Map<String, double>? connections,
  })  : id = id ?? const Uuid().v4(),
        connections = connections ?? {};

  /// Creates a copy of this node with the specified fields updated
  Node copyWith({
    String? name,
    Offset? position,
    int? floor,
    NodeType? type,
    Map<String, double>? connections,
  }) {
    return Node(
      id: id,
      name: name ?? this.name,
      position: position ?? this.position,
      floor: floor ?? this.floor,
      type: type ?? this.type,
      connections: connections ?? Map.from(this.connections),
    );
  }

  /// Add a connection to another node with a specific distance
  void addConnection(String nodeId, double distance) {
    connections[nodeId] = distance;
  }

  /// Convert Node to Map for storing in local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'x': position.dx,
      'y': position.dy,
      'floor': floor,
      'type': type.index,
      'connections': connections,
    };
  }

  /// Create a Node from a Map (retrieved from local storage)
  factory Node.fromMap(Map<String, dynamic> map) {
    return Node(
      id: map['id'],
      name: map['name'],
      position: Offset(map['x'], map['y']),
      floor: map['floor'],
      type: NodeType.values[map['type']],
      connections: Map<String, double>.from(map['connections']),
    );
  }
}

enum NodeType { room, staircase, elevator, entrance, exit, hallway, other }
