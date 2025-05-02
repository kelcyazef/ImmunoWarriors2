import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/anticorps.dart';
import '../../models/agent_pathogene.dart';
import '../../providers/game_providers.dart';
import 'combat_simulation_screen.dart';

/// Screen for preparing for combat by selecting antibodies
class CombatPreparationScreen extends ConsumerWidget {
  final String enemyBaseName;
  final List<AgentPathogene> enemyPathogens;
  
  const CombatPreparationScreen({
    super.key,
    required this.enemyBaseName,
    required this.enemyPathogens,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final resources = ref.watch(resourcesProvider);
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    
    // Available antibodies for selection
    final availableAntibodies = [
      AnticorpsFactory.createLymphocyteT(),
      AnticorpsFactory.createKillerCell(),
      AnticorpsFactory.createMacrophage(),
      AnticorpsFactory.createLymphocyteB(),
    ];
    
    // Tracks selected antibodies
    final selectedAntibodies = <Anticorps>[];
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Préparation au Combat'),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StatefulBuilder(
        builder: (context, setState) {
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
                    // Enemy base information
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Pathogènes détectés:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...enemyPathogens.map((pathogen) => _buildPathogenListItem(context, pathogen)),
                          ],
                        ),
                      ),
                    ),
                    
                    // Antibody selection section
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sélection des Anticorps', 
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${selectedAntibodies.length} sélectionnés',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            ...availableAntibodies.map((antibody) => _buildAntibodySelectionItem(
                              context,
                              antibody,
                              selectedAntibodies.contains(antibody),
                              (isSelected) {
                                setState(() {
                                  if (isSelected) {
                                    if (!selectedAntibodies.contains(antibody)) {
                                      selectedAntibodies.add(antibody);
                                    }
                                  } else {
                                    selectedAntibodies.remove(antibody);
                                  }
                                });
                              },
                            )),
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
                    ),
                  ],
                ),
              ),
              
              // Action button
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
                    // Consume resources
                    resources.consumeEnergie(totalEnergyCost);
                    resources.consumeBiomateriaux(totalBiomaterialCost);
                    
                    // Navigate to combat simulation screen
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CombatSimulationScreen(
                        enemyBaseName: enemyBaseName,
                        playerAntibodies: List.from(selectedAntibodies),
                        enemyPathogens: enemyPathogens,
                      ),
                    ));
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyBlue, // Navy blue color for button
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Déployer les Anticorps',
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
                    Text(' ${antibody.healthPoints}/${antibody.maxHealthPoints}'),
                    const SizedBox(width: 8),
                    Icon(Icons.flash_on, color: Colors.amber[700], size: 14),
                    Text(' ${antibody.damage}'),
                    const SizedBox(width: 8),
                    _getAttackTypeChip(antibody.attackType),
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
