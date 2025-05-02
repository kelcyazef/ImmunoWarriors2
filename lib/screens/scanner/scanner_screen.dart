import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/game_providers.dart';
import '../../models/user_profile.dart';
import '../combat/combat_preparation_screen.dart';

/// Screen for scanning and discovering enemy viral bases
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
        ),
        title: const Text('Scanner'),
        backgroundColor: navyBlue, // Navy blue for app bar
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: userProfileAsync.when(
        data: (userProfile) => _buildScannerContent(context, userProfile, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error', style: TextStyle(color: Colors.black87)),
        ),
      ),
    );
  }
  
  Widget _buildScannerContent(BuildContext context, UserProfile? userProfile, WidgetRef ref) {
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    
    // If userProfile is null, show a friendly message
    if (userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: navyBlue),
            const SizedBox(height: 16),
            const Text('Unable to load profile data', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: navyBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Scanner header
        Card(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                      backgroundColor: const Color(0xFFDEEBFF),
                      child: Icon(Icons.radar, size: 28, color: navyBlue), // Navy blue color for accents
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scanner Biologique', 
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Détection de Bases Virales hostiles',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Refresh the enemy bases provider
                      final refreshedProvider = ref.refresh(enemyBasesProvider);
                      
                      // Listen to the refreshed provider once to show appropriate message
                      refreshedProvider.whenData((bases) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Scan complet. ${bases.length} bases virales détectées.')),
                        );
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Lancer un Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Enemy bases list - dynamic from Firestore
        Consumer(
          builder: (context, ref, child) {
            final enemyBasesAsync = ref.watch(enemyBasesProvider);
            
            return enemyBasesAsync.when(
              data: (enemyBases) {
                if (enemyBases.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Aucune base virale détectée. Lancez un scan pour rechercher des cibles.'),
                    ),
                  );
                }
                
                return Column(
                  children: enemyBases.map((base) => _buildEnemyBaseCard(context, base, ref)).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Erreur lors du chargement des bases: $error'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildEnemyBaseCard(BuildContext context, Map<String, dynamic> base, WidgetRef ref) {
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    final textTheme = Theme.of(context).textTheme;
    
    // Set color based on threat level
    Color threatColor;
    switch (base['threatLevel']) {
      case 'Facile':
        threatColor = Colors.green[700]!;
        break;
      case 'Modéré':
        threatColor = Colors.orange[700]!;
        break;
      case 'Difficile':
        threatColor = Colors.red[700]!;
        break;
      default:
        threatColor = Colors.blue[700]!;
    }
    
    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with base name and threat level
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Threat level icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: threatColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.bug_report, color: threatColor, size: 32),
                ),
                const SizedBox(width: 16),
                // Base details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        base['name'],
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            base['owner'], 
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: threatColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber, size: 14, color: threatColor),
                                const SizedBox(width: 4),
                                Text(
                                  base['threatLevel'],
                                  style: TextStyle(color: threatColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // Pathogens section
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.coronavirus, size: 18, color: Colors.grey[800]),
                const SizedBox(width: 8),
                Text(
                  'Pathogènes détectés:', 
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pathogen chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (base['pathogens'] as List).map((pathogen) {
                return Chip(
                  backgroundColor: const Color(0xFFF0F4F8),
                  side: BorderSide(color: Colors.grey[300]!),
                  label: Text(pathogen, style: TextStyle(color: Colors.grey[800])),
                  avatar: Icon(Icons.coronavirus, size: 16, color: threatColor),
                  padding: const EdgeInsets.all(4),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Rewards and attack button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Rewards section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, size: 18, color: Colors.grey[800]),
                        const SizedBox(width: 8),
                        Text(
                          'Récompenses:', 
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Reward icons with values
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, color: Colors.amber[700], size: 18),
                          Text(' ${base['rewards']['energie']}', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Icon(Icons.biotech_outlined, color: Colors.green[700], size: 18),
                          Text(' ${base['rewards']['biomateriaux']}', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Icon(Icons.psychology, color: Colors.purple[700], size: 18),
                          Text(' ${base['rewards']['points']}', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Attack button
                SizedBox(
                  width: 150,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Check if user has enough resources
                      final resources = ref.read(resourcesProvider);
                      final requiredEnergie = 10; // Base energy cost for attack
                      
                      if (resources.currentEnergie < requiredEnergie) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Énergie insuffisante pour lancer une attaque!')),
                        );
                        return;
                      }
                      
                      // Navigate to combat preparation screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CombatPreparationScreen(targetBase: base),
                        ),
                      );
                    },
                    icon: const Icon(Icons.security, size: 20),
                    label: const Text('Attaquer', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
