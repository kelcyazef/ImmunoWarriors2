import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/firestore_providers.dart';

/// Energy refill options dialog implementation
/// To be included in the HomeScreen
extension EnergyRefillExtension on ConsumerState {
  /// Shows energy refill options dialog
  void showEnergyRefillOptions(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final firestoreService = ref.read(firestoreServiceProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Recharger l\'Énergie',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Energy display
            const Icon(
              Icons.battery_charging_full,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Comment voulez-vous récupérer de l\'énergie?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Option 1: Wait for free regeneration
            ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.blue),
              title: const Text('Attendre la régénération'),
              subtitle: const Text('1 énergie toutes les 2 minutes'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('L\'énergie se régénère naturellement avec le temps.'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            
            // Option 2: Watch an ad (simulated)
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: const Text('Regarder une publicité'),
              subtitle: const Text('+20 énergie instantanément'),
              onTap: () async {
                Navigator.pop(context);
                
                // Show ad loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement de la vidéo...'),
                      ],
                    ),
                  ),
                );
                
                // Simulate ad watching
                await Future.delayed(const Duration(seconds: 2));
                Navigator.of(context).pop(); // Close loading dialog
                
                try {
                  // Update energy in Firestore
                  final userProfile = await firestoreService.getUserProfileOnce(user.uid);
                  if (userProfile != null) {
                    final newEnergy = userProfile.currentEnergie + 20;
                    await firestoreService.updateUserProfile(
                      user.uid,
                      {'currentEnergie': newEnergy > 100 ? 100 : newEnergy},
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vous avez gagné 20 points d\'énergie!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            
            // Option 3: Exchange biomaterials for energy
            ListTile(
              leading: const Icon(Icons.science, color: Colors.purple),
              title: const Text('Échanger des biomatériaux'),
              subtitle: const Text('10 biomatériaux = +30 énergie'),
              onTap: () async {
                Navigator.pop(context);
                
                try {
                  final userProfile = await firestoreService.getUserProfileOnce(user.uid);
                  if (userProfile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur: Profil non trouvé'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  if (userProfile.currentBiomateriaux < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pas assez de biomatériaux (minimum 10 requis)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  // Confirm biomaterial exchange
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmer l\'échange'),
                      content: const Text('Échanger 10 biomatériaux contre 30 points d\'énergie?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('ANNULER'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('CONFIRMER'),
                        ),
                      ],
                    ),
                  ) ?? false;
                  
                  if (!confirmed) return;
                  
                  // Process exchange
                  final newBiomaterials = userProfile.currentBiomateriaux - 10;
                  final newEnergy = userProfile.currentEnergie + 30;
                  
                  await firestoreService.updateUserProfile(
                    user.uid,
                    {
                      'currentEnergie': newEnergy > 100 ? 100 : newEnergy,
                      'currentBiomateriaux': newBiomaterials,
                    },
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Échange réussi! +30 énergie'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FERMER'),
          ),
        ],
      ),
    );
  }
}
