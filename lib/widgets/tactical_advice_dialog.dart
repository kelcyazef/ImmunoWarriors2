import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immunowarriors/providers/gemini_providers.dart';

/// A simplified dialog that displays tactical advice for combat
class TacticalAdviceDialog extends ConsumerWidget {
  final Map<String, dynamic> playerState;
  final Map<String, dynamic> enemyBase;
  
  const TacticalAdviceDialog({
    Key? key, 
    required this.playerState, 
    required this.enemyBase,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Debug information to help diagnose issues
    print('TacticalAdviceDialog build method called');
    print('PlayerState: $playerState');
    print('EnemyBase: $enemyBase');
    
    // Validate data before making the API call
    if (playerState.isEmpty || enemyBase.isEmpty) {
      print('Error: Empty data in tactical advice dialog');
      return _buildErrorDialog(context, 'Données insuffisantes pour l\'analyse tactique');
    }
    
    final data = {
      'playerState': playerState,
      'enemyBase': enemyBase,
    };
    
    // Debug the data being passed to the provider
    print('Data being passed to tacticalAdviceProvider: $data');
    
    // Immediately create a listener to show we're responsive
    Future.delayed(const Duration(milliseconds: 500), () {
      print('Checking if dialog is still shown...');
    });
    
    // Add auto-timeout after 5 seconds to avoid freezing
    ref.watch(tacticalAdviceTimeoutProvider);
    // Use watchImmediately to ensure we get updates
    final adviceAsync = ref.watch(tacticalAdviceProvider(data));
    print('Current state of advice: ${adviceAsync.toString()}');
    
    return AlertDialog(
      title: const Text(
        'Analyse Tactique',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 300,
        height: 200,
        child: adviceAsync.when(
          data: (advice) {
            print('Displaying advice data: $advice');
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber[800], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Recommandation:',
                        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    child: Text(
                      advice,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () {
            print('Currently showing loading state');
            
            // Add a timer to automatically show fallback after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              // Check if we're still mounted and in loading state
              if (adviceAsync is AsyncLoading && context.mounted) {
                print('Still loading after 2s, showing fallback...');
                // Try to invalidate provider to stop loading
                ref.invalidate(tacticalAdviceProvider(data));
                // Show fallback
                Navigator.of(context).pop();
                if (context.mounted) {
                  showDialog(
                    context: context, 
                    builder: (_) => _buildFallbackAdvice(context),
                  );
                }
              }
            });
            
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Analyzing...'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Force showing fallback advice if user clicks
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (_) => _buildFallbackAdvice(context),
                      );
                    },
                    child: const Text('Skip Waiting'),
                  ),
                ],
              ),
            );
          },
          error: (error, stack) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strategy Recommendation:',
                  style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Deploy Killer Cells against ${enemyBase['units'] != null && (enemyBase['units'] as List).isNotEmpty ? (enemyBase['units'] as List)[0]['name'] : 'enemies'}. Use Macrophages as tanks and Lymphocytes for support.",
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Understood'),
        ),
      ],
    );
  }
  
  // Helper method to build a simple error dialog
  Widget _buildErrorDialog(BuildContext context, String errorMessage) {
    return AlertDialog(
      title: const Text(
        'Analyse Tactique Indisponible',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[700]),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cette fonctionnalité nécessite une connexion internet.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
  
  // Builds a fallback advice dialog when the API times out or fails
  Widget _buildFallbackAdvice(BuildContext context) {
    // Determine enemy name if available
    String enemyName = 'enemies';
    if (enemyBase['units'] != null && 
        (enemyBase['units'] as List).isNotEmpty && 
        (enemyBase['units'] as List)[0]['name'] != null) {
      enemyName = (enemyBase['units'] as List)[0]['name'];
    }
    
    return AlertDialog(
      title: const Text(
        'Analyse Tactique',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        textAlign: TextAlign.center,
      ),
      content: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommandation de stratégie:',
              style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Déployez les Killer Cells contre $enemyName. Utilisez les Macrophages comme tanks et les Lymphocytes comme soutien.",
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Understood'),
        ),
      ],
    );
  }
}
