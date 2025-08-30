import 'package:flutter/material.dart';
import '../services/navigation_provider.dart';

class LocationSimulator extends StatelessWidget {
  final NavigationProvider navigationProvider;
  
  const LocationSimulator({
    super.key, 
    required this.navigationProvider,
  });

  @override
  Widget build(BuildContext context) {
    // Only show this widget when auto-tracking is enabled
    if (!navigationProvider.isUsingAutoTracking) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Movement Simulator (Debug)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DirectionButton(
                icon: Icons.arrow_upward,
                onPressed: () => _simulateMovement(const Offset(0, -20)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DirectionButton(
                icon: Icons.arrow_back,
                onPressed: () => _simulateMovement(const Offset(-20, 0)),
              ),
              const SizedBox(width: 50),
              _DirectionButton(
                icon: Icons.arrow_forward,
                onPressed: () => _simulateMovement(const Offset(20, 0)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DirectionButton(
                icon: Icons.arrow_downward,
                onPressed: () => _simulateMovement(const Offset(0, 20)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.stairs),
                label: const Text('Floor Up'),
                onPressed: () => _changeFloor(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[200],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.stairs_outlined),
                label: const Text('Floor Down'),
                onPressed: () => _changeFloor(-1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[200],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _simulateMovement(Offset movement) {
    navigationProvider.locationService.simulateMovement(movement);
  }
  
  void _changeFloor(int change) {
    final currentFloor = navigationProvider.locationService.currentFloor;
    navigationProvider.locationService.detectFloorChange(currentFloor + change);
  }
}

class _DirectionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  
  const _DirectionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: 32,
      color: Colors.blue,
      style: IconButton.styleFrom(
        backgroundColor: Colors.blue[50],
      ),
    );
  }
}
