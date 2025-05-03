import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/energy_manager.dart';
import '../providers/game_providers.dart';

/// A dialog that shows energy status and options to regenerate energy
class EnergyDialog extends ConsumerStatefulWidget {
  const EnergyDialog({super.key});

  @override
  ConsumerState<EnergyDialog> createState() => _EnergyDialogState();
}

class _EnergyDialogState extends ConsumerState<EnergyDialog> {
  Timer? _refreshTimer;
  final TextEditingController _biomaterialsController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    // Refresh timer for countdown display
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _biomaterialsController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${(duration.inSeconds % 60)}s';
    } else {
      return '${duration.inHours}h ${(duration.inMinutes % 60)}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AlertDialog(
        title: Text('Erreur'),
        content: Text('Vous devez être connecté pour gérer votre énergie.'),
      );
    }
    
    final energyManager = ref.watch(energyManagerProvider(user.uid));
    // Use resourcesProvider instead of directly watching a user profile
    final resources = ref.watch(resourcesProvider);
    final currentBiomaterials = resources.currentBiomateriaux;
    
    return AlertDialog(
      title: const Text(
        'Énergie',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Energy status
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: energyManager.currentEnergy / EnergyManager.maxEnergy,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getEnergyColor(energyManager.currentEnergy / EnergyManager.maxEnergy),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${energyManager.currentEnergy}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/ ${EnergyManager.maxEnergy}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Regeneration info
          if (!energyManager.isEnergyFull) ...[
            Text(
              'Prochaine énergie dans: ${_formatDuration(energyManager.timeUntilNextEnergy)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Énergie complète dans: ${_formatDuration(energyManager.timeUntilFullEnergy)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
          
          // Energy boost options
          const Text(
            'Augmenter votre énergie',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Watch ad option
          ElevatedButton.icon(
            onPressed: () => _handleWatchAd(context, energyManager),
            icon: const Icon(Icons.videocam),
            label: Text('Regarder une vidéo (+${EnergyManager.energyPerAd})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          const SizedBox(height: 12),
          
          // Biomaterials exchange
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _biomaterialsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Biomatériaux',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // Parse value safely
                  int? inputValue = int.tryParse(_biomaterialsController.text);
                  if (inputValue == null || currentBiomaterials < inputValue) {
                    return;
                  }
                  _handleBiomaterialsExchange(
                    context, 
                    energyManager, 
                    inputValue,
                    currentBiomaterials,
                  );
                },
                child: Text('Échanger (${(int.tryParse(_biomaterialsController.text) ?? 0) * EnergyManager.energyPerBiomaterial}✨)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            'Biomatériaux disponibles: $currentBiomaterials',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('FERMER'),
        ),
      ],
    );
  }
  
  Color _getEnergyColor(double percentage) {
    if (percentage > 0.7) {
      return Colors.green;
    } else if (percentage > 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  Future<void> _handleWatchAd(BuildContext context, EnergyManager energyManager) async {
    final scaffold = ScaffoldMessenger.of(context);
    
    // Show loading indicator
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
    
    try {
      final success = await energyManager.addEnergyFromAd();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (success) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text('Vous avez gagné ${EnergyManager.energyPerAd} points d\'énergie!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger la vidéo. Réessayez plus tard.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      Navigator.of(context).pop();
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _handleBiomaterialsExchange(
    BuildContext context, 
    EnergyManager energyManager, 
    int biomaterialsToSpend,
    int currentBiomaterials,
  ) async {
    final scaffold = ScaffoldMessenger.of(context);
    
    if (biomaterialsToSpend <= 0) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant valide de biomatériaux.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (biomaterialsToSpend > currentBiomaterials) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Vous n\'avez pas assez de biomatériaux.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Confirm exchange
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'échange'),
        content: Text(
          'Échanger $biomaterialsToSpend biomatériaux contre ${biomaterialsToSpend * EnergyManager.energyPerBiomaterial} points d\'énergie?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Traitement de l\'échange...'),
          ],
        ),
      ),
    );
    
    try {
      final success = await energyManager.purchaseEnergyWithBiomaterials(biomaterialsToSpend);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (success) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text('Vous avez gagné ${biomaterialsToSpend * EnergyManager.energyPerBiomaterial} points d\'énergie!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Échange échoué. Vérifiez vos biomatériaux.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      Navigator.of(context).pop();
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Shows the energy dialog
void showEnergyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const EnergyDialog(),
  );
}
