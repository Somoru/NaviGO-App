import 'package:flutter/material.dart';
import '../models/building.dart';
import '../models/node.dart';

class MapRenderer extends StatelessWidget {
  final Floor floor;
  final String? selectedNodeId;
  final String? destinationNodeId;
  final List<String>? pathNodeIds;
  final Function(String nodeId)? onNodeTap;

  const MapRenderer({
    super.key,
    required this.floor,
    this.selectedNodeId,
    this.destinationNodeId,
    this.pathNodeIds,
    this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: floor.size.width,
      height: floor.size.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: CustomPaint(
        painter: MapPainter(
          nodes: floor.nodes,
          selectedNodeId: selectedNodeId,
          destinationNodeId: destinationNodeId,
          pathNodeIds: pathNodeIds ?? [],
        ),
        child: GestureDetector(
          onTapDown: (details) {
            _handleTap(details.localPosition);
          },
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    if (onNodeTap == null) return;

    // Find the closest node to the tap position
    // We'll use a simple distance calculation
    Node? closestNode;
    double closestDistance = double.infinity;

    for (var node in floor.nodes) {
      double distance = (node.position - position).distance;
      if (distance < closestDistance && distance < 30) {
        // 30 is the tap radius
        closestDistance = distance;
        closestNode = node;
      }
    }

    if (closestNode != null) {
      onNodeTap!(closestNode.id);
    }
  }
}

class MapPainter extends CustomPainter {
  final List<Node> nodes;
  final String? selectedNodeId;
  final String? destinationNodeId;
  final List<String> pathNodeIds;

  MapPainter({
    required this.nodes,
    this.selectedNodeId,
    this.destinationNodeId,
    required this.pathNodeIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connections between nodes
    _drawConnections(canvas);

    // Draw path if available
    _drawPath(canvas);

    // Draw nodes
    _drawNodes(canvas);
  }

  void _drawConnections(Canvas canvas) {
    final Paint connectionPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Create a set to track which connections we've already drawn
    Set<String> drawnConnections = {};

    for (var node in nodes) {
      for (var entry in node.connections.entries) {
        String targetNodeId = entry.key;
        // Check if this connection has already been drawn
        String connectionId = node.id + '-' + targetNodeId;
        String reverseConnectionId = targetNodeId + '-' + node.id;

        if (drawnConnections.contains(connectionId) ||
            drawnConnections.contains(reverseConnectionId)) {
          continue;
        }

        drawnConnections.add(connectionId);

        // Find the target node
        Node? targetNode;
        try {
          targetNode = nodes.firstWhere((n) => n.id == targetNodeId);
        } catch (e) {
          continue; // Skip if target node is not found
        }

        // Draw the connection line
        canvas.drawLine(node.position, targetNode.position, connectionPaint);
      }
    }
  }

  void _drawPath(Canvas canvas) {
    if (pathNodeIds.length < 2) return;

    final Paint pathPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw path segments
    for (int i = 0; i < pathNodeIds.length - 1; i++) {
      String currentNodeId = pathNodeIds[i];
      String nextNodeId = pathNodeIds[i + 1];

      // Find the nodes
      Node? currentNode;
      Node? nextNode;
      try {
        currentNode = nodes.firstWhere((node) => node.id == currentNodeId);
        nextNode = nodes.firstWhere((node) => node.id == nextNodeId);
      } catch (e) {
        continue; // Skip if either node is not found
      }

      // Draw the path segment
      canvas.drawLine(
        currentNode.position,
        nextNode.position,
        pathPaint,
      );
    }
  }

  void _drawNodes(Canvas canvas) {
    for (var node in nodes) {
      // Determine node color and size based on type and selection
      Color nodeColor;
      double nodeRadius;

      if (node.id == selectedNodeId) {
        nodeColor = Colors.green;
        nodeRadius = 15;
      } else if (node.id == destinationNodeId) {
        nodeColor = Colors.red;
        nodeRadius = 15;
      } else if (pathNodeIds.contains(node.id)) {
        nodeColor = Colors.orange;
        nodeRadius = 10;
      } else {
        // Color based on node type
        switch (node.type) {
          case NodeType.staircase:
            nodeColor = Colors.blue;
            break;
          case NodeType.elevator:
            nodeColor = Colors.purple;
            break;
          case NodeType.entrance:
            nodeColor = Colors.green[700]!;
            break;
          case NodeType.exit:
            nodeColor = Colors.red[700]!;
            break;
          case NodeType.hallway:
            nodeColor = Colors.amber;
            break;
          default:
            nodeColor = Colors.blue[800]!;
        }
        nodeRadius = 8;
      }

      // Draw node circle
      final Paint nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(node.position, nodeRadius, nodePaint);

      // Draw node border
      final Paint borderPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(node.position, nodeRadius, borderPaint);

      // Draw node label
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.name,
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(node.position.dx - textPainter.width / 2,
            node.position.dy + nodeRadius + 2),
      );
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.destinationNodeId != destinationNodeId ||
        oldDelegate.pathNodeIds != pathNodeIds;
  }
}
