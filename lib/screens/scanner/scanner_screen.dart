import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/firestore_providers.dart';
import '../../models/user_profile.dart';

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
    
    // Mock data for enemy bases
    final enemyBases = [
      {
        'name': 'Base Virale Alpha',
        'owner': 'Système',
        'threatLevel': 'Facile',
        'pathogens': ['Influenza Virus', 'Candida Albicans'],
        'rewards': {'energie': 20, 'biomateriaux': 15, 'points': 5},
      },
      {
        'name': 'Base Virale Beta',
        'owner': 'Système',
        'threatLevel': 'Modéré',
        'pathogens': ['Staphylococcus', 'Influenza Virus', 'Influenza Virus'],
        'rewards': {'energie': 35, 'biomateriaux': 25, 'points': 10},
      },
      {
        'name': 'Base Virale Gamma',
        'owner': 'Système',
        'threatLevel': 'Difficile',
        'pathogens': ['Staphylococcus', 'Staphylococcus', 'Candida Albicans', 'Influenza Virus'],
        'rewards': {'energie': 50, 'biomateriaux': 40, 'points': 15},
      },
    ];
    
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
                ElevatedButton.icon(
                  onPressed: () {
                    // Simulate scan refresh
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scan complet. 3 bases virales détectées.')),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Lancer un Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Enemy bases list
        ...enemyBases.map((base) => _buildEnemyBaseCard(context, base, ref)),
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
        threatColor = Colors.green;
        break;
      case 'Modéré':
        threatColor = Colors.orange;
        break;
      case 'Difficile':
        threatColor = Colors.red;
        break;
      default:
        threatColor = Colors.blue;
    }
    
    return Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: threatColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bug_report, color: threatColor, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        base['name'],
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Propriétaire: ${base['owner']}', 
                              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: threatColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              base['threatLevel'],
                              style: TextStyle(color: threatColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Pathogènes détectés:', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (base['pathogens'] as List).map((pathogen) {
                return Chip(
                  backgroundColor: const Color(0xFFEDF2F7),
                  label: Text(pathogen),
                  avatar: const Icon(Icons.coronavirus, size: 16),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Récompenses potentielles:', style: textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.amber[700], size: 16),
                        Text(' ${base['rewards']['energie']}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Icon(Icons.biotech_outlined, color: Colors.green[700], size: 16),
                        Text(' ${base['rewards']['biomateriaux']}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Icon(Icons.psychology, color: Colors.purple[700], size: 16),
                        Text(' ${base['rewards']['points']}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to combat preparation screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Préparation à l\'attaque contre ${base['name']}')),
                    );
                  },
                  icon: const Icon(Icons.security, size: 18),
                  label: const Text('Attaquer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
