import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immunowarriors/providers/gemini_providers.dart';

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
    
    final adviceAsync = ref.watch(tacticalAdviceProvider(data));
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Analyse Tactique',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: adviceAsync.when(
                  data: (advice) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      advice,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Analyzing enemy base and formulating strategy...'),
                      ],
                    ),
                  ),
                  error: (error, stack) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Échec de l\'analyse tactique',
                        style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vérifiez votre connexion internet et réessayez.',
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Tactical Analysis (Fallback):",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Based on your resources and the enemy composition, deploy a balanced force. Use Lymphocyte T and Killer Cells against ${enemyBase['units'] != null && (enemyBase['units'] as List).isNotEmpty ? (enemyBase['units'] as List)[0]['name'] : 'the enemy'} while Macrophages provide tankiness. Prioritize targets with higher damage output first.",
                              style: const TextStyle(height: 1.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Error details: $error",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Understood'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build error dialog
  Widget _buildErrorDialog(BuildContext context, String errorMessage) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Analyse Tactique Indisponible',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
