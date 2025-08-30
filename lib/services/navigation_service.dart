import '../models/building.dart';
import '../models/node.dart';
import '../models/navigation.dart';
import 'package:flutter/material.dart';

class NavigationService {
  // Implementation of Dijkstra's algorithm for finding the shortest path
  NavigationRoute? findShortestPath(
      Building building, String startNodeId, String endNodeId) {
    // Find the start and end nodes
    Node? startNode;
    Node? endNode;
    int startFloor = 0;
    int endFloor = 0;

    // Find nodes across all floors
    for (var floor in building.floors) {
      for (var node in floor.nodes) {
        if (node.id == startNodeId) {
          startNode = node;
          startFloor = node.floor;
        }
        if (node.id == endNodeId) {
          endNode = node;
          endFloor = node.floor;
        }
      }
    }

    // If we couldn't find both nodes, return null
    if (startNode == null || endNode == null) {
      return null;
    }

    // Create a map of all nodes for easy lookup
    Map<String, Node> allNodes = {};
    for (var floor in building.floors) {
      for (var node in floor.nodes) {
        allNodes[node.id] = node;
      }
    }

    // Initialize data structures for Dijkstra's algorithm
    Map<String, double> distances = {}; // Map of node id to distance from start
    Map<String, String?> previousNodes =
        {}; // Map of node id to previous node in path
    List<String> unvisitedNodes = []; // List of unvisited nodes

    // Set initial distances to infinity for all nodes except start node
    for (var nodeId in allNodes.keys) {
      distances[nodeId] = double.infinity;
      previousNodes[nodeId] = null;
      unvisitedNodes.add(nodeId);
    }
    distances[startNodeId] = 0;

    // Process nodes until we've visited all or found the destination
    while (unvisitedNodes.isNotEmpty) {
      // Find unvisited node with smallest distance
      unvisitedNodes.sort((a, b) => distances[a]!.compareTo(distances[b]!));
      String currentNodeId = unvisitedNodes.first;

      // If we've reached the end node or the smallest distance is infinity (unreachable), stop
      if (currentNodeId == endNodeId ||
          distances[currentNodeId] == double.infinity) {
        break;
      }

      // Remove current node from unvisited
      unvisitedNodes.remove(currentNodeId);

      // Get the current node
      Node currentNode = allNodes[currentNodeId]!;

      // Check each neighbor of the current node
      for (var entry in currentNode.connections.entries) {
        String neighborId = entry.key;
        double weight = entry.value;

        // Calculate distance through current node to neighbor
        double distanceThroughCurrent = distances[currentNodeId]! + weight;

        // If this path is shorter than the previously known shortest path
        if (distanceThroughCurrent < distances[neighborId]!) {
          distances[neighborId] = distanceThroughCurrent;
          previousNodes[neighborId] = currentNodeId;
        }
      }
    }

    // If we couldn't reach the end node, return null
    if (previousNodes[endNodeId] == null) {
      return null;
    }

    // Reconstruct the path
    List<String> path = [];
    String? currentId = endNodeId;
    while (currentId != null) {
      path.insert(0, currentId);
      currentId = previousNodes[currentId];
    }

    // Create navigation steps
    List<NavigationStep> steps = _createNavigationSteps(path, allNodes);

    // Create and return the navigation route
    return NavigationRoute(
      pathNodeIds: path,
      steps: steps,
      startFloor: startFloor,
      endFloor: endFloor,
    );
  }

  // Create navigation steps from a list of node IDs
  List<NavigationStep> _createNavigationSteps(
      List<String> pathNodeIds, Map<String, Node> allNodes) {
    List<NavigationStep> steps = [];

    if (pathNodeIds.isEmpty) return steps;

    // Add start step
    Node startNode = allNodes[pathNodeIds.first]!;
    steps.add(NavigationStep(
      nodeId: startNode.id,
      instruction: "Start at ${startNode.name}",
      floor: startNode.floor,
      type: StepType.start,
    ));

    // Add intermediate steps
    for (int i = 1; i < pathNodeIds.length - 1; i++) {
      Node prevNode = allNodes[pathNodeIds[i - 1]]!;
      Node currentNode = allNodes[pathNodeIds[i]]!;
      Node nextNode = allNodes[pathNodeIds[i + 1]]!;

      StepType stepType;
      String instruction;

      if (currentNode.floor != prevNode.floor) {
        // Floor change
        if (currentNode.type == NodeType.staircase) {
          stepType = StepType.stairs;
          instruction = "Take stairs to ${_getFloorName(currentNode.floor)}";
        } else if (currentNode.type == NodeType.elevator) {
          stepType = StepType.elevator;
          instruction = "Take elevator to ${_getFloorName(currentNode.floor)}";
        } else {
          stepType = StepType.straight;
          instruction = "Go to ${_getFloorName(currentNode.floor)}";
        }
      } else {
        // Determine turn direction based on relative positions
        // This is a simplified approach and might need refinement for real applications
        stepType = _determineStepType(
            prevNode.position, currentNode.position, nextNode.position);
        instruction = "Go to ${currentNode.name}";
      }

      steps.add(NavigationStep(
        nodeId: currentNode.id,
        instruction: instruction,
        floor: currentNode.floor,
        type: stepType,
      ));
    }

    // Add destination step
    Node endNode = allNodes[pathNodeIds.last]!;
    steps.add(NavigationStep(
      nodeId: endNode.id,
      instruction: "Reach ${endNode.name}",
      floor: endNode.floor,
      type: StepType.destination,
    ));

    return steps;
  }

  // Helper method to determine step type based on turn direction
  StepType _determineStepType(
      Offset prevPos, Offset currentPos, Offset nextPos) {
    // Calculate direction vectors
    Offset prevToCurrentVec =
        Offset(currentPos.dx - prevPos.dx, currentPos.dy - prevPos.dy);
    Offset currentToNextVec =
        Offset(nextPos.dx - currentPos.dx, nextPos.dy - currentPos.dy);

    // Calculate the angle between the two vectors
    double crossProduct = prevToCurrentVec.dx * currentToNextVec.dy -
        prevToCurrentVec.dy * currentToNextVec.dx;

    // Determine turn direction based on cross product
    if (crossProduct > 0.1) {
      return StepType.turnLeft;
    } else if (crossProduct < -0.1) {
      return StepType.turnRight;
    } else {
      return StepType.straight;
    }
  }

  // Helper method to get floor name
  String _getFloorName(int floor) {
    if (floor == 0) return "Ground Floor";
    if (floor > 0) return "Floor $floor";
    return "Basement ${-floor}";
  }
}
