import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/game_providers.dart';
import '../../providers/firestore_providers.dart';

/// Screen for showing player's progress, victories, and immune memory archives
class ArchivesScreen extends ConsumerWidget {
  const ArchivesScreen({super.key});
  
  // Format date helper
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Build demo signature card for display when no real signatures exist
  Widget _buildSignatureCard(BuildContext context, String name, String type, TextTheme textTheme) {
    final typeColors = {
      'Virus': Colors.red[700],
      'Bacterie': Colors.blue[700],
      'Champignon': Colors.amber[700],
    };
    
    // Simplify pathogen name if too long
    String displayName = name;
    if (name.length > 20) {
      final parts = name.split(' ');
      displayName = parts.isNotEmpty ? parts.first : name.substring(0, 10);
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: (typeColors[type] ?? Colors.purple[700])!.withOpacity(0.2),
              child: Icon(Icons.bug_report, size: 14, color: typeColors[type] ?? Colors.purple[700]),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                displayName,
                style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (typeColors[type] ?? Colors.purple[700])!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                type,
                style: TextStyle(fontSize: 10, color: typeColors[type] ?? Colors.purple[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build combat history item
  Widget _buildCombatHistoryItem(BuildContext context, DateTime date, String enemyName, String result, int rewardPoints) {
    final isVictory = result == 'Victory';
    final backgroundColor = isVictory ? Colors.green[50] : Colors.red[50];
    final borderColor = isVictory ? Colors.green[200] : Colors.red[200];
    final iconColor = isVictory ? Colors.green[700] : Colors.red[700];
    final icon = isVictory ? Icons.check_circle : Icons.cancel;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enemyName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDate(date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isVictory ? 'Victoire' : 'Défaite',
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isVictory)
                Text(
                  '+$rewardPoints pts',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ],
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
  
  // Build player stats section
  Widget _buildPlayerStatsSection(BuildContext context, dynamic profile, dynamic memoireImmunitaire) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, Icons.science, '${memoireImmunitaire.signatureCount}', 'Pathogènes\nDécouverts'),
                _buildStatItem(context, Icons.military_tech, '${profile?.victories ?? 0}', 'Victoires'),
                _buildStatItem(context, Icons.biotech, '${profile?.researchPoints ?? 0}', 'Points de\nRecherche'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Build battle history section
  Widget _buildBattleHistorySection(BuildContext context, List<Map<String, dynamic>> battleHistory, TextTheme textTheme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historique des Combats', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            
            // List of combat history items
            if (battleHistory.isNotEmpty)
              ...battleHistory.map((combat) => _buildCombatHistoryItem(
                context, 
                combat['timestamp'] != null ? (combat['timestamp'] as Timestamp).toDate() : DateTime.now(), 
                combat['enemyBaseName'] as String, 
                combat['victory'] == true ? 'Victory' : 'Defeat', 
                combat['rewardPoints'] as int? ?? 0,
              )).toList(),
            
            // Show empty state if no combat history
            if (battleHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucun combat enregistré'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Build immune memory section
  Widget _buildImmuneMemorySection(BuildContext context, dynamic memoireImmunitaire, TextTheme textTheme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mémoire Immunitaire', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            
            // Grid of pathogen signatures
            if (memoireImmunitaire.signatureCount > 0)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.0,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: memoireImmunitaire.signatureCount,
                  itemBuilder: (context, index) {
                    final signature = memoireImmunitaire.signatures[index];
                    final pathogen = signature.pathogenName;
                    final type = pathogen.contains('Virus') ? 'Virus' : 
                                pathogen.contains('Staphylococcus') || pathogen.contains('E. Coli') ? 'Bacterie' : 'Champignon';
                    return _buildSignatureCard(context, pathogen, type, textTheme);
                  },
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucun pathogène découvert'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final memoireImmunitaire = ref.watch(memoireImmunitaireProvider);
    final userProfile = ref.watch(userProfileProvider);
    
    return Scaffold(
      appBar: null, // Removed AppBar, will use HomeScreen's AppBar
      body: userProfile.when(
        data: (profile) {
          // Watch the battle history provider
          final battleHistoryAsync = ref.watch(battleHistoryProvider);
          
          return battleHistoryAsync.when(
            data: (battleHistory) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Player stats section
                  _buildPlayerStatsSection(context, profile, memoireImmunitaire),
                  
                  // Battle history section
                  _buildBattleHistorySection(context, battleHistory, textTheme),
                  
                  // Immune memory section
                  _buildImmuneMemorySection(context, memoireImmunitaire, textTheme),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Erreur de chargement: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur de profil: $error')),
      ),
    );
  }
}
