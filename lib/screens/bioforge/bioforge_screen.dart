import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/agent_pathogene.dart';
import '../../providers/game_providers.dart';
import '../../providers/firestore_providers.dart';
import '../../models/memoire_immunitaire.dart';

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
  
  // Available pathogens for selection
  List<AgentPathogene> _availablePathogens = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with default pathogens (will be updated from immune memory)
    _availablePathogens = [
      PathogeenFactory.createInfluenzaVirus(),
      PathogeenFactory.createStaphBacteria(),
      PathogeenFactory.createCandidaFungus(),
    ];
  }
  
  // Update available pathogens based on immune memory
  void _updateAvailablePathogens(MemoireImmunitaire memoireImmunitaire) {
    // Keep the default pathogens
    final updatedPathogens = [
      PathogeenFactory.createInfluenzaVirus(),
      PathogeenFactory.createStaphBacteria(),
      PathogeenFactory.createCandidaFungus(),
    ];
    
    // Add pathogens from immune memory
    for (var signature in memoireImmunitaire.signatures) {
      // We can't pass custom names to PathogeenFactory methods,
      // so we'll just add the default ones if they're not already in the list
      final pathogenName = signature.pathogenName;
      if (pathogenName.contains('Virus') && !updatedPathogens.any((p) => p.name == 'Influenza Virus')) {
        updatedPathogens.add(PathogeenFactory.createInfluenzaVirus());
      } else if ((pathogenName.contains('Staphylococcus') || pathogenName.contains('E. Coli')) && 
                !updatedPathogens.any((p) => p.name == 'Staphylococcus')) {
        updatedPathogens.add(PathogeenFactory.createStaphBacteria());
      } else if (pathogenName.contains('Candida') && 
                !updatedPathogens.any((p) => p.name == 'Candida Albicans')) {
        updatedPathogens.add(PathogeenFactory.createCandidaFungus());
      }
    }
    
    // Update state
    setState(() {
      _availablePathogens = updatedPathogens;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final resources = ref.watch(resourcesProvider);
    final memoireImmunitaire = ref.watch(memoireImmunitaireProvider);
    const navyBlue = Color(0xFF0A2342); // Navy blue color constant
    final textTheme = Theme.of(context).textTheme;
    
    // Update available pathogens based on immune memory
    if (memoireImmunitaire.signatureCount > 0 && _availablePathogens.length <= 3) {
      _updateAvailablePathogens(memoireImmunitaire);
    }
    
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
        ),
        title: const Text('Bio-Forge'),
        backgroundColor: navyBlue, // Navy blue app bar
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: userProfileAsync.when(
        data: (userProfile) {
          // Calculate base deployment cost
          final baseDeploymentCost = _selectedPathogens.length * 10;
          final canDeploy = resources.currentBiomateriaux >= baseDeploymentCost && _selectedPathogens.isNotEmpty;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Configuration de Base Virale',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: navyBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configurez votre base virale pour la déployer dans l\'écosystème',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                
                // Resources card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.biotech, color: Colors.green[700], size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bio-Matériaux Disponibles',
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${resources.currentBiomateriaux} unités',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Base name input
                Text(
                  'Nom de la Base',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  showCursor: true, // Make cursor visible
                  cursorColor: Theme.of(context).primaryColor, // Use theme color for cursor
                  decoration: InputDecoration(
                    hintText: 'Entrez un nom pour votre base virale',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.edit),
                    focusedBorder: OutlineInputBorder( // Highlight when focused
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  initialValue: _baseName,
                  onChanged: (value) {
                    setState(() {
                      _baseName = value;
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Public/Private toggle
                Text(
                  'Visibilité',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: SwitchListTile(
                    title: const Text('Base publique'),
                    subtitle: const Text('Visible et attaquable par les autres joueurs'),
                    value: _isPublic,
                    activeColor: navyBlue,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Pathogens selection
                Text(
                  'Sélection de Pathogènes',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionnez les pathogènes à inclure dans votre base virale',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                
                // Available pathogens
                ...List.generate(_availablePathogens.length, (index) {
                  final pathogen = _availablePathogens[index];
                  final isSelected = _selectedPathogens.contains(pathogen);
                  
                  return Card(
                    elevation: isSelected ? 2 : 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? navyBlue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPathogens.remove(pathogen);
                          } else {
                            _selectedPathogens.add(pathogen);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected ? navyBlue.withOpacity(0.1) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.coronavirus,
                                color: isSelected ? navyBlue : Colors.grey[600],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pathogen.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Type: ${pathogen.attackType}, Attaque: ${pathogen.damage}, PV: ${pathogen.healthPoints}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: navyBlue,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedPathogens.add(pathogen);
                                  } else {
                                    _selectedPathogens.remove(pathogen);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                
                const SizedBox(height: 24),
                
                // Selected pathogens summary
                Text(
                  'Pathogènes sélectionnés (${_selectedPathogens.length})',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedPathogens.map((pathogen) {
                      return Chip(
                        label: Text(pathogen.name),
                        backgroundColor: navyBlue.withOpacity(0.1),
                        avatar: const Icon(Icons.coronavirus, size: 16),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedPathogens.remove(pathogen);
                          });
                        },
                      );
                    }).toList(),
                  ),
                
                const SizedBox(height: 24),
                
                // Deployment section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Déploiement',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coût de déploiement:',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$baseDeploymentCost bio-matériaux',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: canDeploy ? Colors.green[700] : Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: ElevatedButton.icon(
                                onPressed: canDeploy ? () {
                                  // Get current user ID
                                  final userId = ref.read(userProfileProvider).value?.id;
                                  
                                  if (userId != null) {
                                    // Prepare base data
                                    final baseData = {
                                      'name': _baseName,
                                      'owner': ref.read(userProfileProvider).value?.displayName ?? 'Joueur',
                                      'ownerId': userId,
                                      'isPublic': _isPublic,
                                      'threatLevel': _selectedPathogens.length <= 2 ? 'Facile' : 
                                                    _selectedPathogens.length <= 4 ? 'Modéré' : 'Difficile',
                                      'pathogens': _selectedPathogens.map((p) => p.name).toList(),
                                      'createdAt': DateTime.now().millisecondsSinceEpoch,
                                      'rewards': {
                                        'energie': 10 + (_selectedPathogens.length * 5),
                                        'biomateriaux': 5 + (_selectedPathogens.length * 3),
                                        'points': _selectedPathogens.length * 2,
                                      }
                                    };
                                    
                                    // Save to Firestore
                                    ref.read(firestoreServiceProvider).saveViralBase(userId, baseData);
                                    
                                    // Consume resources
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
                                  } else {
                                    // Show error if user not logged in
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Erreur: Utilisateur non connecté'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } : null,
                                icon: const Icon(Icons.cloud_upload),
                                label: const Text('Déployer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: navyBlue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[400],
                                  disabledForegroundColor: Colors.white70,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error'),
        ),
      ),
    );
  }
  
  // Helper method to build a selected pathogen item
  Widget _buildSelectedPathogenItem(BuildContext context, AgentPathogene pathogen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.coronavirus),
        title: Text(pathogen.name),
        subtitle: Text('Type: ${pathogen.attackType}, Attaque: ${pathogen.damage}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _selectedPathogens.remove(pathogen);
            });
          },
        ),
      ),
    );
  }
}
