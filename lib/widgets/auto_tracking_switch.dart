import 'package:flutter/material.dart';
import '../services/navigation_provider.dart';

class AutoTrackingSwitch extends StatelessWidget {
  final NavigationProvider navigationProvider;
  
  const AutoTrackingSwitch({
    super.key,
    required this.navigationProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(33, 150, 243, 0.1), // Light blue with 10% opacity
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color.fromRGBO(33, 150, 243, 0.3), // Light blue with 30% opacity
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Tracking',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  navigationProvider.isUsingAutoTracking
                      ? 'Using sensor data to track your position'
                      : 'Select your position manually',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: navigationProvider.isUsingAutoTracking,
            onChanged: (value) {
              if (!navigationProvider.isTrackingInitialized && value) {
                // Show a snackbar to indicate initialization is happening
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Initializing sensors...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
              
              // Handle the toggle without async/await
              // Store the scaffold messenger to avoid context issues
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              navigationProvider.toggleAutoTracking().then((success) {
                if (!success && value) {
                  // Show error message if we failed to enable tracking
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Failed to initialize sensors. Please check permissions.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
