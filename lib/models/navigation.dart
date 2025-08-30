class NavigationRoute {
  final List<String> pathNodeIds;
  final List<NavigationStep> steps;
  final int startFloor;
  final int endFloor;
  final bool requiresFloorChange;

  NavigationRoute({
    required this.pathNodeIds,
    required this.steps,
    required this.startFloor,
    required this.endFloor,
  }) : requiresFloorChange = startFloor != endFloor;

  // Utility method to get text directions
  String getTextDirections() {
    return steps.map((step) => step.instruction).join(' → ');
  }
}

class NavigationStep {
  final String nodeId;
  final String instruction;
  final int floor;
  final StepType type;

  NavigationStep({
    required this.nodeId,
    required this.instruction,
    required this.floor,
    required this.type,
  });
}

enum StepType {
  start,
  straight,
  turnLeft,
  turnRight,
  stairs,
  elevator,
  destination,
}
