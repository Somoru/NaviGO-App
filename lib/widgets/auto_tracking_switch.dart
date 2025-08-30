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
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
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
            onChanged: (value) async {
              if (!navigationProvider.isTrackingInitialized && value) {
                // Show a snackbar to indicate initialization is happening
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Initializing sensors...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
              
              final success = await navigationProvider.toggleAutoTracking();
              
              if (!success && value) {
                // Show error message if we failed to enable tracking
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to initialize sensors. Please check permissions.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
