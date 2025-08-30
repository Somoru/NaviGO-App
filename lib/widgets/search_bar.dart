import 'package:flutter/material.dart';
import '../models/building.dart';
import '../models/node.dart';

class DestinationSearchBar extends StatefulWidget {
  final Building building;
  final int currentFloor;
  final Function(String nodeId) onDestinationSelected;

  const DestinationSearchBar({
    super.key,
    required this.building,
    required this.currentFloor,
    required this.onDestinationSelected,
  });

  @override
  State<DestinationSearchBar> createState() => _DestinationSearchBarState();
}

class _DestinationSearchBarState extends State<DestinationSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  List<Node> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Collect all nodes from all floors
    List<Node> allNodes = [];
    for (final floor in widget.building.floors) {
      allNodes.addAll(floor.nodes);
    }

    // Filter nodes by query
    final results = allNodes
        .where((node) => 
            node.name.toLowerCase().contains(query) || 
            node.id.toLowerCase().contains(query))
        .toList();

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  void _selectDestination(Node node) {
    widget.onDestinationSelected(node.id);
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
    FocusScope.of(context).unfocus(); // Hide keyboard
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a destination...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        if (_isSearching && _searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final node = _searchResults[index];
                final floor = widget.building.floors
                    .firstWhere((f) => f.nodes.contains(node));
                final isCurrentFloor = floor.number == widget.currentFloor;
                
                return ListTile(
                  title: Text(node.name),
                  subtitle: Text('Floor ${floor.number}'),
                  trailing: Icon(
                    isCurrentFloor
                        ? Icons.location_on
                        : Icons.stairs,
                    color: isCurrentFloor ? Colors.blue : Colors.orange,
                  ),
                  onTap: () => _selectDestination(node),
                );
              },
            ),
          ),
      ],
    );
  }
}
