import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/navigation_provider.dart';
import '../services/building_service.dart';
import '../widgets/map_renderer.dart';
import '../widgets/auto_tracking_switch.dart';
import '../widgets/location_simulator.dart';
import '../widgets/search_bar.dart';
import '../models/building.dart';
import 'package:dropdown_button2/dropdown_button2';ackage:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/navigation_provider.dart';
import '../services/building_service.dart';
import '../widgets/map_renderer.dart';
import '../widgets/auto_tracking_switch.dart';
import '../widgets/location_simulator.dart';
import '../models/building.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final BuildingService _buildingService = BuildingService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuilding();
  }

  Future<void> _loadBuilding() async {
    final building = await _buildingService.loadMockBuilding();

    if (!mounted) return;

    Provider.of<NavigationProvider>(context, listen: false)
        .setBuilding(building);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NaviGO Indoor Navigation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Consumer<NavigationProvider>(
        builder: (context, navigationProvider, child) {
      final building = navigationProvider.building;
      final currentFloor = navigationProvider.currentFloor;

      if (building == null || currentFloor == null) {
        return const Center(child: Text('No building data available'));
      }

      return Column(
        children: [
          _buildFloorSelector(navigationProvider, building),
          _buildMapArea(navigationProvider, currentFloor),
          _buildLocationSelectors(navigationProvider),
          _buildDirections(navigationProvider),
        ],
      );
    });
  }

  Widget _buildFloorSelector(
      NavigationProvider navigationProvider, Building building) {
    return Column(
      children: [
        // Add search bar above floor selector
        DestinationSearchBar(
          building: building,
          currentFloor: navigationProvider.currentFloor!.number,
          onDestinationSelected: (nodeId) {
            navigationProvider.selectDestination(nodeId);
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Floor:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ...List.generate(building.floors.length, (index) {
                final floor = building.floors[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(floor.name),
                    selected: navigationProvider.currentFloorIndex == index,
                    onSelected: (_) =>
                        navigationProvider.setCurrentFloorIndex(index),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapArea(
      NavigationProvider navigationProvider, Floor currentFloor) {
    // Get user location if auto tracking is enabled and on current floor
    Offset? userLocation;
    final isUsingAutoTracking = navigationProvider.isUsingAutoTracking;
    
    if (isUsingAutoTracking) {
      final locationService = navigationProvider.locationService;
      if (locationService.currentFloor == currentFloor.number) {
        userLocation = locationService.currentPosition;
      }
    }
    
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              child: MapRenderer(
                floor: currentFloor,
                selectedNodeId: navigationProvider.selectedNodeId,
                destinationNodeId: navigationProvider.destinationNodeId,
                pathNodeIds: navigationProvider.pathNodeIdsOnCurrentFloor,
                onNodeTap: (nodeId) =>
                    _handleNodeTap(navigationProvider, nodeId),
                showUserLocation: isUsingAutoTracking,
                userLocation: userLocation,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNodeTap(NavigationProvider navigationProvider, String nodeId) {
    if (navigationProvider.selectedNodeId == null) {
      // If no node is selected, set this as the starting point
      navigationProvider.selectNode(nodeId);
    } else if (navigationProvider.destinationNodeId == null) {
      // If starting point is selected but no destination, set this as the destination
      navigationProvider.selectDestination(nodeId);
    } else {
      // If both are already selected, start over with this as the new starting point
      navigationProvider.clearRoute();
      navigationProvider.selectNode(nodeId);
    }
  }

  Widget _buildLocationSelectors(NavigationProvider navigationProvider) {
    final building = navigationProvider.building!;

    // Create a flat list of all nodes across all floors
    final allNodes = building.floors.expand((floor) => floor.nodes).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Auto-tracking switch
          AutoTrackingSwitch(navigationProvider: navigationProvider),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildNodeDropdown(
                  value: navigationProvider.selectedNodeId,
                  hint: 'Select start point',
                  nodes: allNodes,
                  onChanged: navigationProvider.isUsingAutoTracking 
                    ? null // Disable manual selection when auto-tracking is on
                    : (value) {
                        if (value != null) {
                          navigationProvider.selectNode(value);
                        }
                      },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNodeDropdown(
                  value: navigationProvider.destinationNodeId,
                  hint: 'Select destination',
                  nodes: allNodes,
                  onChanged: (value) {
                    if (value != null) {
                      navigationProvider.selectDestination(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: navigationProvider.selectedNodeId != null &&
                    navigationProvider.destinationNodeId != null
                ? () => navigationProvider.calculateRoute()
                : null,
            child: const Text('Find Path'),
          ),
          TextButton(
            onPressed: () => navigationProvider.clearRoute(),
            child: const Text('Clear'),
          ),
          
          // Add location simulator for testing
          const SizedBox(height: 8),
          LocationSimulator(navigationProvider: navigationProvider),
        ],
      ),
    );
  }

  Widget _buildNodeDropdown({
    String? value,
    required String hint,
    required List<dynamic> nodes,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        hint: Text(hint),
        value: value,
        items: nodes.map((node) {
          return DropdownMenuItem<String>(
            value: node.id,
            child: Text('${node.name} (Floor ${node.floor})'),
          );
        }).toList(),
        onChanged: onChanged,
        buttonStyleData: const ButtonStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16),
          height: 40,
          width: double.infinity,
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
        ),
        dropdownStyleData: const DropdownStyleData(
          maxHeight: 200,
        ),
      ),
    );
  }

  Widget _buildDirections(NavigationProvider navigationProvider) {
    final route = navigationProvider.currentRoute;

    if (route == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Directions:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(route.getTextDirections()),
          if (route.requiresFloorChange)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Note: This route requires changing floors.',
                style: TextStyle(
                    color: Colors.red[700], fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
