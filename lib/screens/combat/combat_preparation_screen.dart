import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/agent_pathogene.dart';
import '../../models/anticorps.dart';
import '../../providers/game_providers.dart';
import '../../models/agent_pathogene_factory.dart' hide Virus, Bacteria, Fungus;
import '../../widgets/tactical_advice_dialog.dart';
import 'combat_simulation_screen.dart';

/// Screen for preparing for combat by selecting antibodies
class CombatPreparationScreen extends ConsumerWidget {
  final Map<String, dynamic> targetBase;
  
  const CombatPreparationScreen({
    super.key,
    required this.targetBase,
  });
  
  // Show tactical advice dialog using Gemini AI
  void _showTacticalAdvice(BuildContext context, List<AgentPathogene> enemyPathogens, WidgetRef ref) {
    print('_showTacticalAdvice called');
    
    // Prepare player state data
    final resources = ref.read(resourcesProvider);
    final playerState = {
      'resources': {
        'energy': resources.currentEnergie,
        'biomaterials': resources.currentBiomateriaux,
      },
      'availableUnits': [
        {'name': 'Lymphocyte T', 'type': 'Combat', 'hp': 100, 'damage': 30},
        {'name': 'Killer Cell', 'type': 'Assault', 'hp': 80, 'damage': 40},
        {'name': 'Macrophage', 'type': 'Tank', 'hp': 150, 'damage': 20},
        {'name': 'Lymphocyte B', 'type': 'Support', 'hp': 90, 'damage': 25},
      ],
      'researchLevel': 1, // Using a default value since ResourcesDefensive doesn't have researchLevel
    };
    
    print('Player state prepared: $playerState');
    
    // Prepare enemy base data
    final enemyBase = {
      'units': enemyPathogens.map((pathogen) => {
        'name': pathogen.name,
        'type': pathogen.runtimeType.toString(),
        'hp': pathogen.healthPoints,
        'damage': pathogen.damage,
      }).toList(),
      'weaknesses': _getEnemyBaseWeaknesses(enemyPathogens),
    };
    
    print('Enemy base prepared: $enemyBase');
    
    // Show tactical advice dialog
    showDialog(
      context: context,
      builder: (context) => TacticalAdviceDialog(
        playerState: playerState,
        enemyBase: enemyBase,
      ),
    );
  }
  
  // Helper method to get enemy weaknesses based on pathogen types
  String _getEnemyBaseWeaknesses(List<AgentPathogene> pathogens) {
    final typeCount = {
      'Virus': 0,
      'Bacterie': 0,
      'Champignon': 0,
    };
    
    for (final pathogen in pathogens) {
      if (pathogen is Virus) {
        typeCount['Virus'] = (typeCount['Virus'] ?? 0) + 1;
      } else if (pathogen is Bacterie) {
        typeCount['Bacterie'] = (typeCount['Bacterie'] ?? 0) + 1;
      } else if (pathogen is Champignon) {
        typeCount['Champignon'] = (typeCount['Champignon'] ?? 0) + 1;
      }
    }
    
    // Determine weaknesses based on enemy composition
    final weaknesses = <String>[];
    if ((typeCount['Virus'] ?? 0) > 0) {
      weaknesses.add('Chemical attacks');
    }
    if ((typeCount['Bacterie'] ?? 0) > 0) {
      weaknesses.add('Physical penetration');
    }
    if ((typeCount['Champignon'] ?? 0) > 0) {
      weaknesses.add('Area effects');
    }
    
    return weaknesses.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = ref.watch(resourcesProvider);
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    
    // Available antibodies for selection
    final availableAntibodies = [
      AnticorpsFactory.createLymphocyteT(),
      AnticorpsFactory.createKillerCell(),
      AnticorpsFactory.createMacrophage(),
      AnticorpsFactory.createLymphocyteB(),
    ];
    
    // Using a stateful variable to track selections across rebuilds
    final ValueNotifier<List<Anticorps>> selectedAntibodiesNotifier = ValueNotifier<List<Anticorps>>([]);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
        ),
        title: const Text('Préparation au Combat'),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Anticorps>>(
        valueListenable: selectedAntibodiesNotifier,
        builder: (context, selectedAntibodies, _) {
          // Get enemy base details
          final String enemyBaseName = targetBase['name'] ?? 'Base Inconnue';
          final List<dynamic> pathogenNames = targetBase['pathogens'] ?? [];
          final Map<String, dynamic> rewards = targetBase['rewards'] ?? {'energie': 0, 'biomateriaux': 0, 'points': 0};
          
          // Use rewards in the UI
          final int energieReward = rewards['energie'] ?? 0;
          final int biomateriauxReward = rewards['biomateriaux'] ?? 0;
          final int pointsReward = rewards['points'] ?? 0;
          
          // Create rewards text for display
          final rewardsText = 'Récompenses potentielles: $energieReward énergie, $biomateriauxReward biomatériaux, $pointsReward points';
          
          // Convert pathogen names to AgentPathogene objects
          final List<AgentPathogene> enemyPathogens = pathogenNames.map((name) {
            // Create appropriate pathogen based on name
            if (name.toString().contains('Influenza')) {
              return AgentPathogeneFactory.createVirus(name: name.toString());
            } else if (name.toString().contains('Staphylococcus') || name.toString().contains('E. Coli')) {
              return AgentPathogeneFactory.createBacteria(name: name.toString());
            } else {
              return AgentPathogeneFactory.createFungus(name: name.toString());
            }
          }).toList();
          
          // Calculate total resources required
          int totalEnergyCost = selectedAntibodies.fold(
            0, (sum, antibody) => sum + antibody.energyCost);
          int totalBiomaterialCost = selectedAntibodies.fold(
            0, (sum, antibody) => sum + antibody.biomaterialCost);
          
          // Check if we have enough resources
          bool canDeploy = selectedAntibodies.isNotEmpty && 
                           totalEnergyCost <= resources.currentEnergie &&
                           totalBiomaterialCost <= resources.currentBiomateriaux;
          
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Enemy base information section
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.red.withOpacity(0.2),
                                    child: Icon(Icons.coronavirus, size: 28, color: Colors.red[700]),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          enemyBaseName, 
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${enemyPathogens.length} pathogènes hostiles détectés',
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(rewardsText, 
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Pathogènes détectés:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  // Tactical advice button with shadow for better visibility
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showTacticalAdvice(context, enemyPathogens, ref),
                                      icon: const Icon(Icons.psychology, size: 16),
                                      label: const Text('Analyse Tactique'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF26C6DA),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        minimumSize: const Size(0, 0), // Prevent infinite width
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...enemyPathogens.map((pathogen) => _buildPathogenListItem(context, pathogen)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      text: 'Sélection des Anticorps',
                                    ),
                                    key: const Key('selection-title'),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      text: '${selectedAntibodies.length} sélectionnés',
                                    ),
                                    key: const Key('selection-count'),
                                    style: TextStyle(
                                      color: navyBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...availableAntibodies.map((antibody) => _buildAntibodySelectionItem(
                                context, antibody, selectedAntibodies.contains(antibody),
                                (isSelected) {
                                  final updatedList = List<Anticorps>.from(selectedAntibodies);
                                  if (isSelected) {
                                    if (!updatedList.contains(antibody)) {
                                      updatedList.add(antibody);
                                    }
                                  } else {
                                    updatedList.remove(antibody);
                                  }
                                  selectedAntibodiesNotifier.value = updatedList;
                                },
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ressources requises:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.amber[700], size: 20),
                        Text(
                          ' $totalEnergyCost / ${resources.currentEnergie}',
                          style: TextStyle(
                            color: totalEnergyCost > resources.currentEnergie 
                                ? Colors.red 
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.biotech_outlined, color: Colors.green[700], size: 20),
                        Text(
                          ' $totalBiomaterialCost / ${resources.currentBiomateriaux}',
                          style: TextStyle(
                            color: totalBiomaterialCost > resources.currentBiomateriaux 
                                ? Colors.red 
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, -2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: canDeploy ? () {
                    // Print debug info
                    debugPrint('Deploying antibodies: ${selectedAntibodies.length}');
                    debugPrint('Enemy pathogens: ${enemyPathogens.length}');
                    
                    // Consume resources
                    resources.consumeEnergie(totalEnergyCost);
                    resources.consumeBiomateriaux(totalBiomaterialCost);
                    
                    // Navigate to combat simulation
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => CombatSimulationScreen(
                          enemyBaseName: enemyBaseName,
                          playerAntibodies: List<Anticorps>.from(selectedAntibodies),
                          enemyPathogens: enemyPathogens,
                        ),
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyBlue, // Navy blue color for button
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Déployer les Anticorps',
                    ),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPathogenListItem(BuildContext context, AgentPathogene pathogen) {
    final textTheme = Theme.of(context).textTheme;
    
    // Icon and color based on pathogen type
    IconData typeIcon;
    Color typeColor;
    
    if (pathogen is Virus) {
      typeIcon = Icons.bug_report;
      typeColor = Colors.purple;
    } else if (pathogen is Bacterie) {
      typeIcon = Icons.coronavirus;
      typeColor = Colors.orange;
    } else if (pathogen is Champignon) {
      typeIcon = Icons.spa;
      typeColor = Colors.teal;
    } else {
      typeIcon = Icons.help;
      typeColor = Colors.grey;
    }
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: typeColor.withOpacity(0.2),
        child: Icon(typeIcon, color: typeColor, size: 20),
      ),
      title: Text(
        pathogen.name,
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.favorite, color: Colors.red[300], size: 14),
          Text(' ${pathogen.healthPoints}/${pathogen.maxHealthPoints}'),
          const SizedBox(width: 8),
          Icon(Icons.shield, color: Colors.blue[300], size: 14),
          Text(' ${pathogen.armor.toInt()}'),
          const SizedBox(width: 8),
          Icon(Icons.flash_on, color: Colors.amber[700], size: 14),
          Text(' ${pathogen.damage}'),
        ],
      ),
      trailing: _getAttackTypeChip(pathogen.attackType),
    );
  }
  
  Widget _buildAntibodySelectionItem(
    BuildContext context, 
    Anticorps antibody, 
    bool isSelected,
    Function(bool) onSelectionChanged,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Icon and color based on antibody type
    IconData typeIcon;
    Color typeColor;
    
    if (antibody is AnticorpsOffensif) {
      typeIcon = Icons.security;
      typeColor = Colors.red;
    } else if (antibody is AnticorpsDefensif) {
      typeIcon = Icons.healing;
      typeColor = Colors.green;
    } else if (antibody is AnticorpsMarqueur) {
      typeIcon = Icons.track_changes;
      typeColor = Colors.blue;
    } else {
      typeIcon = Icons.coronavirus;
      typeColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? colorScheme.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: typeColor.withOpacity(0.2),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  antibody.name,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red[300], size: 14),
                    Flexible(
                      child: Text(' ${antibody.healthPoints}/${antibody.maxHealthPoints}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.flash_on, color: Colors.amber[700], size: 14),
                    Flexible(
                      child: Text(' ${antibody.damage}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _getAttackTypeChip(antibody.attackType),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.amber[700], size: 14),
                    Text(' ${antibody.energyCost}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(Icons.biotech_outlined, color: Colors.green[700], size: 14),
                    Text(' ${antibody.biomaterialCost}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Checkbox(
            value: isSelected,
            onChanged: (value) => onSelectionChanged(value ?? false),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
  
  Widget _getAttackTypeChip(AttackType attackType) {
    // Color and label based on attack type
    Color chipColor;
    String label;
    
    switch (attackType) {
      case AttackType.physical:
        chipColor = Colors.orange;
        label = 'Physique';
        break;
      case AttackType.chemical:
        chipColor = Colors.green;
        label = 'Chimique';
        break;
      case AttackType.energetic:
        chipColor = Colors.blue;
        label = 'Énergétique';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
