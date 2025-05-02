import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_providers.dart';

/// Screen for showing player's progress, victories, and immune memory archives
class ArchivesScreen extends ConsumerWidget {
  const ArchivesScreen({super.key});
  
  // Format date helper
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Build demo signature card for display when no real signatures exist
  Widget _buildDemoSignatureCard(BuildContext context, String name, String type, TextTheme textTheme) {
    final typeColors = {
      'Virus': Colors.red[700],
      'Bacterie': Colors.blue[700],
      'Champignon': Colors.amber[700],
    };
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: (typeColors[type] ?? Colors.purple[700])!.withOpacity(0.2),
                  child: Icon(Icons.bug_report, size: 16, color: typeColors[type] ?? Colors.purple[700]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(type, style: const TextStyle(fontSize: 12)),
                  backgroundColor: (typeColors[type] ?? Colors.purple[700])!.withOpacity(0.1),
                  labelStyle: TextStyle(color: typeColors[type] ?? Colors.purple[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bonus de dégâts: +20%', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                Text('Réduction de coût: -10%', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Build combat history card
  Widget _buildCombatHistoryCard(BuildContext context, Map<String, dynamic> combat) {
    final bool isVictory = combat['result'] == 'Victory';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isVictory ? Colors.green[100] : Colors.red[100],
          child: Icon(
            isVictory ? Icons.check : Icons.close,
            color: isVictory ? Colors.green[700] : Colors.red[700],
          ),
        ),
        title: Text(
          combat['enemyName'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Date: ${_formatDate(combat['date'])}\nPoints: ${combat["rewardPoints"]}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.article_outlined),
          onPressed: () {
            // Show battle details
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chronique détaillée non disponible en mode démo')),
            );
          },
        ),
      ),
    );
  }
  
  // Helper to build stat item
  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue[700], size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final memoireImmunitaire = ref.watch(memoireImmunitaireProvider);
    
    // Add dummy combat history if none exists
    final List<Map<String, dynamic>> combatHistory = [
      {
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'enemyName': 'Base Virale Alpha',
        'result': 'Victory',
        'rewardPoints': 15,
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 4)),
        'enemyName': 'Base Virale Beta',
        'result': 'Defeat',
        'rewardPoints': 0,
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'enemyName': 'Base Virale Gamma',
        'result': 'Victory',
        'rewardPoints': 20,
      },
    ];
    
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        title: const Text('Archives'),
        backgroundColor: navyBlue, // Navy blue app bar
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Player stats card
          Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.purple.withOpacity(0.2),
                        child: Icon(Icons.bar_chart, color: Colors.purple[700]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistiques du Joueur',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Résumé des performances et découvertes',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Stats summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        Icons.security,
                        memoireImmunitaire.signatures.isEmpty ? '3' : memoireImmunitaire.signatures.length.toString(),
                        'Pathogènes Identifiés',
                      ),
                      _buildStatItem(
                        context,
                        Icons.science,
                        (memoireImmunitaire.researchPoints + 35).toString(),
                        'Points de Recherche',
                      ),
                      _buildStatItem(
                        context,
                        Icons.military_tech,
                        '7',
                        'Victoires',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Immune memory section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Text(
              'Mémoire Immunitaire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Display demo signature cards
          _buildDemoSignatureCard(context, 'Influenza Virus', 'Virus', textTheme),
          _buildDemoSignatureCard(context, 'Staphylococcus Aureus', 'Bacterie', textTheme),
          _buildDemoSignatureCard(context, 'Candida Albicans', 'Champignon', textTheme),
          
          // Battle history section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Text(
              'Historique des Combats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Combat history list
          ...combatHistory.map((combat) => _buildCombatHistoryCard(context, combat)).toList(),
        ],
      ),
    );
  }
}
