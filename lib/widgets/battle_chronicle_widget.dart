import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immunowarriors/providers/gemini_providers.dart';

class BattleChronicleWidget extends ConsumerWidget {
  final Map<String, dynamic> battleData;
  
  const BattleChronicleWidget({
    Key? key,
    required this.battleData,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Improve error handling by checking data validity first
    if (battleData.isEmpty ||
        (battleData['playerUnits'] == null && battleData['enemyUnits'] == null)) {
      return _buildErrorWidget(context, 'Insufficient battle data for generating chronicles');
    }
    
    final chronicleAsync = ref.watch(battleChronicleProvider(battleData));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chroniques de Bataille',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(),
          const SizedBox(height: 8),
          chronicleAsync.when(
            data: (chronicle) => Text(
              chronicle,
              style: const TextStyle(
                height: 1.5,
              ),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating battle chronicle...'),
                  ],
                ),
              ),
            ),
            error: (error, stack) => _buildErrorWidget(context, 'Failed to generate battle chronicle: $error'),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build error widget
  Widget _buildErrorWidget(BuildContext context, String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Chronique Indisponible',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: TextStyle(color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Cette fonctionnalité nécessite une connexion internet.',
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
