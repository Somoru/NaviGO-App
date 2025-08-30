# NaviGO - Indoor Navigation App

NaviGO is a Flutter application for indoor navigation, similar to Google Maps but for indoor spaces. This application provides path finding and directions between rooms in a building.

## Features

- Display a 2D map with multiple floors
  - Floor 1: Gate, Lobby, Canteen, Stairs
  - Floor 2: Stairs, Block A, Room 210
- Floor selection functionality
- Select start point via map click or dropdown
- Select destination via map click or dropdown
- Pathfinding with Dijkstra's algorithm
- Visual representation of:
  - Rooms as nodes
  - Hallways as connections
  - Calculated path highlighted in red
- Step-by-step directions text
- Support for multi-floor navigation

## Future Enhancements

- Support for custom map uploads
- Automatic positioning
- More detailed building layouts
- Advanced path finding with A* algorithm
- Support for accessibility routes

## Technical Details

### Architecture

The app is built with a modular architecture to easily replace the mock map data with real building blueprints:

- **Models**: Define building, floor, node, and navigation data structures
- **Services**: Handle navigation logic and building data
- **Widgets**: Render maps and UI components
- **Screens**: Main app screens and user interactions

### Libraries Used

- **Provider**: For state management
- **Hive & Hive Flutter**: For local storage (prepared for future use)
- **Path Provider**: For file system access
- **Flutter SVG**: For vector graphics support
- **Dropdown Button2**: Enhanced dropdown UI
- **UUID**: For generating unique identifiers

## Getting Started

1. Make sure you have Flutter installed
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Customization

The app is designed to be customizable. You can:

1. Modify the mock building data in `building_service.dart`
2. Create new JSON map definitions following the structure in `generateBuildingJsonTemplate()`
3. Customize the UI appearance in the widgets
