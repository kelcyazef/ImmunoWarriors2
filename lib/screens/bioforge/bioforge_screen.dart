import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/agent_pathogene.dart';
import '../../providers/game_providers.dart';
import '../../providers/firestore_providers.dart';
import '../../models/user_profile.dart';

/// Screen for creating and managing the player's viral base
class BioForgeScreen extends ConsumerStatefulWidget {
  const BioForgeScreen({super.key});

  @override
  ConsumerState<BioForgeScreen> createState() => _BioForgeScreenState();
}

class _BioForgeScreenState extends ConsumerState<BioForgeScreen> {
  // Player's viral base configuration
  String _baseName = 'Ma Base Virale';
  final List<AgentPathogene> _selectedPathogens = [];
  bool _isPublic = true;
  
  // Available pathogens for selection (would be unlocked through gameplay)
  late List<AgentPathogene> _availablePathogens;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with default pathogens
    _availablePathogens = [
      PathogeenFactory.createInfluenzaVirus(),
      PathogeenFactory.createStaphBacteria(),
      PathogeenFactory.createCandidaFungus(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final resources = ref.watch(resourcesProvider);
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        title: const Text('Bio-Forge'),
        backgroundColor: navyBlue, // Navy blue app bar
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: userProfileAsync.when(
        data: (userProfile) => _buildBioForgeContent(context, userProfile, resources),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error', style: const TextStyle(color: Colors.black87)),
        ),
      ),
    );
  }
  
  Widget _buildBioForgeContent(
    BuildContext context, 
    UserProfile? userProfile, 
    resources
  ) {
    final textTheme = Theme.of(context).textTheme;
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    
    // If userProfile is null, show a friendly message
    if (userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined, size: 64, color: navyBlue),
            const SizedBox(height: 16),
            const Text('Unable to load Bio-Forge data', 
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
    
    // Calculate cost for base deployment
    int baseDeploymentCost = 20 + (_selectedPathogens.length * 10);
    bool canDeploy = resources.currentBiomateriaux >= baseDeploymentCost && _selectedPathogens.isNotEmpty;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Base configuration card
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
                      backgroundColor: Colors.green.withOpacity(0.2),
                      child: Icon(Icons.biotech, size: 28, color: Colors.green[700]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuration de Base Virale', 
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ressources disponibles: ${resources.currentBiomateriaux} bio-matériaux',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Base name input
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nom de la Base',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.edit),
                  ),
                  initialValue: _baseName,
                  onChanged: (value) {
                    setState(() {
                      _baseName = value;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Public/Private toggle
                SwitchListTile(
                  title: const Text('Base publique'),
                  subtitle: const Text('Visible et attaquable par les autres joueurs'),
                  value: _isPublic,
                  activeColor: navyBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Selected pathogens
                Text(
                  'Pathogènes sélectionnés (${_selectedPathogens.length}):',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Display selected pathogens or placeholder
                if (_selectedPathogens.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucun pathogène sélectionné',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Column(
                    children: _selectedPathogens.map((pathogen) => 
                      _buildSelectedPathogenItem(context, pathogen),
                    ).toList(),
                  ),
                
                const SizedBox(height: 16),
                
                // Deployment button and cost
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Coût de déploiement: $baseDeploymentCost bio-matériaux',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: canDeploy ? Colors.green[700] : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: canDeploy ? () {
                        // Deploy base
                        resources.consumeBiomateriaux(baseDeploymentCost);
                        
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Base "$_baseName" déployée avec succès!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Reset selections
                        setState(() {
                          _selectedPathogens.clear();
                        });
                      } : null,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Déployer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Available pathogens card
        Card(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pathogènes disponibles:',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sélectionnez des pathogènes pour votre base virale',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // List of available pathogens
                ...List.generate(_availablePathogens.length, (index) {
                  final pathogen = _availablePathogens[index];
                  return _buildAvailablePathogenItem(context, pathogen);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSelectedPathogenItem(BuildContext context, AgentPathogene pathogen) {
    // Icon based on pathogen type
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: typeColor.withOpacity(0.2),
            child: Icon(typeIcon, color: typeColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pathogen.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red[300], size: 14),
                    Text(' ${pathogen.maxHealthPoints}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(Icons.shield, color: Colors.blue[300], size: 14),
                    Text(' ${pathogen.armor.toInt()}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(Icons.flash_on, color: Colors.amber[700], size: 14),
                    Text(' ${pathogen.damage}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () {
              setState(() {
                _selectedPathogens.remove(pathogen);
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvailablePathogenItem(BuildContext context, AgentPathogene pathogen) {
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    
    // Icon based on pathogen type
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
    
    // Check if already selected
    final bool isSelected = _selectedPathogens.any((p) => p.name == pathogen.name);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[200] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.grey[400]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: typeColor.withOpacity(0.2),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pathogen.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red[300], size: 16),
                    Text(' ${pathogen.maxHealthPoints}'),
                    const SizedBox(width: 8),
                    Icon(Icons.shield, color: Colors.blue[300], size: 16),
                    Text(' ${pathogen.armor.toInt()}'),
                    const SizedBox(width: 8),
                    Icon(Icons.flash_on, color: Colors.amber[700], size: 16),
                    Text(' ${pathogen.damage}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Display attack type
                    _getAttackTypeChip(pathogen.attackType),
                    const SizedBox(width: 8),
                    
                    // Display a specialty based on pathogen type
                    if (pathogen is Virus)
                      _buildSpecialtyChip('Mutation Rapide', Colors.purple),
                    if (pathogen is Bacterie)
                      _buildSpecialtyChip('Bouclier Biofilm', Colors.orange),
                    if (pathogen is Champignon)
                      _buildSpecialtyChip('Spores Corrosives', Colors.teal),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isSelected ? null : () {
              setState(() {
                // Create a new instance to avoid shared references
                AgentPathogene newPathogen;
                
                if (pathogen is Virus) {
                  newPathogen = PathogeenFactory.createInfluenzaVirus();
                } else if (pathogen is Bacterie) {
                  newPathogen = PathogeenFactory.createStaphBacteria();
                } else if (pathogen is Champignon) {
                  newPathogen = PathogeenFactory.createCandidaFungus();
                } else {
                  newPathogen = pathogen;
                }
                
                _selectedPathogens.add(newPathogen);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: navyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: Text(isSelected ? 'Ajouté' : 'Ajouter'),
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
  
  Widget _buildSpecialtyChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
