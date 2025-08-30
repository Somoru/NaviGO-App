import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/building.dart';
import '../models/node.dart';
import 'package:flutter/material.dart';

class BuildingService {
  Future<Building> loadMockBuilding() async {
    // Create the mock building data with two floors

    // Floor 1 nodes
    List<Node> floor1Nodes = [
      Node(
        id: 'gate',
        name: 'Gate',
        position: const Offset(100, 100),
        floor: 1,
        type: NodeType.entrance,
      ),
      Node(
        id: 'lobby',
        name: 'Lobby',
        position: const Offset(200, 200),
        floor: 1,
        type: NodeType.hallway,
      ),
      Node(
        id: 'canteen',
        name: 'Canteen',
        position: const Offset(350, 150),
        floor: 1,
        type: NodeType.room,
      ),
      Node(
        id: 'stairs1',
        name: 'Stairs',
        position: const Offset(300, 300),
        floor: 1,
        type: NodeType.staircase,
      ),
    ];

    // Floor 2 nodes
    List<Node> floor2Nodes = [
      Node(
        id: 'stairs2',
        name: 'Stairs',
        position: const Offset(300, 300),
        floor: 2,
        type: NodeType.staircase,
      ),
      Node(
        id: 'blockA',
        name: 'Block A',
        position: const Offset(200, 200),
        floor: 2,
        type: NodeType.hallway,
      ),
      Node(
        id: 'room210',
        name: 'Room 210',
        position: const Offset(100, 150),
        floor: 2,
        type: NodeType.room,
      ),
    ];

    // Add connections between nodes
    // Floor 1 connections
    floor1Nodes[0].addConnection('lobby', 120); // Gate to Lobby
    floor1Nodes[1].addConnection('gate', 120); // Lobby to Gate
    floor1Nodes[1].addConnection('canteen', 180); // Lobby to Canteen
    floor1Nodes[1].addConnection('stairs1', 150); // Lobby to Stairs
    floor1Nodes[2].addConnection('lobby', 180); // Canteen to Lobby
    floor1Nodes[3].addConnection('lobby', 150); // Stairs to Lobby
    floor1Nodes[3]
        .addConnection('stairs2', 50); // Stairs1 to Stairs2 (floor change)

    // Floor 2 connections
    floor2Nodes[0]
        .addConnection('stairs1', 50); // Stairs2 to Stairs1 (floor change)
    floor2Nodes[0].addConnection('blockA', 150); // Stairs2 to Block A
    floor2Nodes[1].addConnection('stairs2', 150); // Block A to Stairs2
    floor2Nodes[1].addConnection('room210', 120); // Block A to Room 210
    floor2Nodes[2].addConnection('blockA', 120); // Room 210 to Block A

    // Create floors
    Floor floor1 = Floor(
      number: 1,
      name: 'Floor 1',
      nodes: floor1Nodes,
      size: const Size(500, 400),
    );

    Floor floor2 = Floor(
      number: 2,
      name: 'Floor 2',
      nodes: floor2Nodes,
      size: const Size(500, 400),
    );

    // Create building with both floors
    return Building(
      name: 'Sample Building',
      floors: [floor1, floor2],
    );
  }

  // Method to load a building from a JSON file
  Future<Building?> loadBuildingFromJson(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);
      return Building.fromMap(jsonData);
    } catch (e) {
      debugPrint('Error loading building from JSON: $e');
      return null;
    }
  }

  // Method to save a building to local storage (would implement with Hive)
  Future<void> saveBuilding(Building building) async {
    // Implementation with Hive would go here
    // For now, we'll just print the data
    debugPrint('Building ${building.name} would be saved to storage');
  }

  // Method to generate a JSON file format for new buildings
  Map<String, dynamic> generateBuildingJsonTemplate() {
    // Create a template for a new building JSON
    return {
      'name': 'New Building',
      'floors': [
        {
          'number': 1,
          'name': 'Floor 1',
          'width': 500,
          'height': 400,
          'nodes': [
            {
              'id': 'node1',
              'name': 'Sample Room',
              'x': 100,
              'y': 100,
              'floor': 1,
              'type': NodeType.room.index,
              'connections': {'node2': 100}
            },
            {
              'id': 'node2',
              'name': 'Another Room',
              'x': 200,
              'y': 200,
              'floor': 1,
              'type': NodeType.room.index,
              'connections': {'node1': 100}
            }
          ]
        }
      ]
    };
  }
}
