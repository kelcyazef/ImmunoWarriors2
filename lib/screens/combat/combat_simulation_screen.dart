import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/anticorps.dart';
import '../../models/agent_pathogene.dart';
import '../../models/combat_manager.dart';
import '../../providers/game_providers.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/auth_providers.dart';
import '../../services/data_sync_service.dart';
import '../../widgets/battle_chronicle_widget.dart';
import 'microscope_background.dart';
import 'cell_visualizations.dart';

/// Screen for visualizing and simulating combat
class CombatSimulationScreen extends ConsumerStatefulWidget {
  final String enemyBaseName;
  final List<Anticorps> playerAntibodies;
  final List<AgentPathogene> enemyPathogens;

  const CombatSimulationScreen({
    super.key,
    required this.enemyBaseName,
    required this.playerAntibodies,
    required this.enemyPathogens,
  });

  @override
  ConsumerState<CombatSimulationScreen> createState() => _CombatSimulationScreenState();
}

class _CombatSimulationScreenState extends ConsumerState<CombatSimulationScreen> {
  bool _isSimulating = false;
  bool _isSimulationComplete = false;
  CombatResult? _combatResult;
  final List<CombatLogEntry> _visibleLogs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startCombat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startCombat() async {
    final combatManager = ref.read(combatManagerProvider);

    // Initialize combat
    combatManager.startCombat(widget.playerAntibodies, widget.enemyPathogens);

    // Start simulation with a small delay to allow UI to build
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isSimulating = true;
    });

    // Run the simulation
    final result = await combatManager.simulateCombat();

    // Display log entries gradually
    for (int i = 0; i < result.combatLog.length; i++) {
      if (mounted) {
        setState(() {
          _visibleLogs.add(result.combatLog[i]);
        });

        // Scroll to bottom
        await Future.delayed(const Duration(milliseconds: 50));
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        // Shorter delay for regular actions, longer for special ones
        await Future.delayed(Duration(
          milliseconds: result.combatLog[i].isSpecialAction ? 800 : 500,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _isSimulating = false;
        _isSimulationComplete = true;
        _combatResult = result;
      });

      // Add a delay before showing results
      await Future.delayed(const Duration(seconds: 2));

      // Navigate to results screen
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => CombatResultScreen(
            enemyBaseName: widget.enemyBaseName,
            combatResult: result,
            playerAntibodies: widget.playerAntibodies,
            enemyPathogens: widget.enemyPathogens,
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final combatManager = ref.watch(combatManagerProvider);

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
        ),
        title: const Text('Simulation de Combat'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Battle visualization with microscopic theme
          Expanded(
            flex: 3,
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.biotech, size: 16, color: Color(0xFF1A237E)),
                        const SizedBox(width: 8),
                        const Text(
                          'Simulation de Combat en Cours',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: MicroscopeBackground(
                            backgroundColor: const Color(0xFFE1F5FE), // Light blue background
                            showCircularView: true,
                            child: Stack(
                              children: [
                                // Combat field with units
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      // Player units
                                      Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blue.withOpacity(0.5)),
                                            ),
                                            child: const Text(
                                              'ÉQUIPE IMMUNITAIRE',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: combatManager.playerUnits.map((unit) {
                                              // Check if this is the current active unit
                                              final isActive = combatManager.isPlayerTurn;
                                              return _buildUnitIcon(context, unit, true, isActive);
                                            }).toList(),
                                          ),
                                          if (combatManager.playerUnits.isEmpty)
                                            const Text('Aucune unité restante',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // VS divider with microscope-themed element
                                      Row(
                                        children: [
                                          Expanded(child: Divider(color: Colors.blue.withOpacity(0.3), thickness: 1.5)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blue.withOpacity(0.3))
                                            ),
                                            child: const Text('VS', 
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo,
                                              )
                                            ),
                                          ),
                                          Expanded(child: Divider(color: Colors.red.withOpacity(0.3), thickness: 1.5)),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Enemy units
                                      Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                                            ),
                                            child: const Text(
                                              'PATHOGÈNES HOSTILES',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: combatManager.enemyUnits.map((unit) {
                                              // Check if this is the current active unit
                                              final isActive = !combatManager.isPlayerTurn;
                                              return _buildUnitIcon(context, unit, false, isActive);
                                            }).toList(),
                                          ),
                                          if (combatManager.enemyUnits.isEmpty)
                                            const Text('Aucune unité restante',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Microscope overlay elements
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Microscope View: 400x',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Combat status overlay
                                if (_isSimulationComplete)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withOpacity(0.7),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: _combatResult?.playerVictory == true 
                                                ? Colors.green.withOpacity(0.8)
                                                : Colors.red.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          ),
                                          child: Text(
                                            _combatResult?.playerVictory == true
                                                ? 'VICTOIRE !'
                                                : 'DÉFAITE...',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Combat log with lab report theme
          Expanded(
            flex: 2,
            child: Card(
              color: Colors.white,
              elevation: 4,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E), // Dark blue for microscope theme
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.science, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Journal de Combat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isSimulating
                        ? ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _visibleLogs.length,
                            itemBuilder: (context, index) {
                              final log = _visibleLogs[index];
                              return _buildLogEntry(context, log);
                            },
                          )
                        : const Center(
                            child: Text('Initialisation du combat...'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitIcon(
    BuildContext context,
    CombatUnit unit,
    bool isPlayerUnit,
    bool isActive,
  ) {
    final healthPercentage = unit.healthPoints / unit.maxHealthPoints;
    
    return Stack(
      children: [
        // Microscopic cell visualization
        CellVisualization(
          unit: unit,
          isPlayerUnit: isPlayerUnit,
          isActive: isActive,
          size: 60,
        ),
        
        // Health bar below the cell
        Positioned(
          bottom: 0,
          left: 5,
          right: 5,
          child: HealthBar(
            healthPercentage: healthPercentage,
            color: _getHealthColor(healthPercentage),
            width: 50,
            height: 5,
          ),
        ),
      ],
    );
  }

  Color _getHealthColor(double healthPercentage) {
    if (healthPercentage > 0.6) {
      return Colors.green;
    } else if (healthPercentage > 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildLogEntry(BuildContext context, CombatLogEntry entry) {
    Color textColor = Colors.black87;
    Color backgroundColor = Colors.transparent;
    IconData? icon;
    
    if (entry.isSpecialAction) {
      backgroundColor = Colors.amber.withOpacity(0.2);
      textColor = Colors.amber.shade900;
      icon = Icons.flash_on;
    } else if (entry.damage != null && entry.damage! > 0) {
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red.shade800;
      icon = Icons.dangerous;
    } else if (entry.healing != null && entry.healing! > 0) {
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green.shade800;
      icon = Icons.healing;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: backgroundColor.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[  
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen for displaying combat results
class CombatResultScreen extends ConsumerWidget {
  final String enemyBaseName;
  final CombatResult combatResult;
  final List<Anticorps> playerAntibodies;
  final List<AgentPathogene> enemyPathogens;

  const CombatResultScreen({
    super.key,
    required this.enemyBaseName,
    required this.combatResult,
    required this.playerAntibodies,
    required this.enemyPathogens,
  });
  
  // Prepare battle data for Gemini
  Map<String, dynamic> _prepareBattleData() {
    // Debug logging
    print('Preparing battle data for Gemini AI');
    print('Player antibodies: ${playerAntibodies.map((a) => a.name).toList()}');
    print('Enemy pathogens: ${enemyPathogens.map((p) => p.name).toList()}');
    
    // Create simplified player units data
    final playerUnitsData = playerAntibodies.map((unit) => {
      'name': unit.name,
      'type': unit.runtimeType.toString(),
      'hp': unit.healthPoints,
      'damage': unit.damage,
    }).toList();
    
    // Create simplified enemy units data
    final enemyUnitsData = enemyPathogens.map((unit) => {
      'name': unit.name,
      'type': unit.runtimeType.toString(),
      'hp': unit.healthPoints,
      'damage': unit.damage,
    }).toList();
    
    // Create significant events from combat log
    final events = combatResult.combatLog
        .where((entry) => entry.isSpecialAction || (entry.damage ?? 0) > 20)
        .map((entry) => entry.message)
        .toList();
    
    return {
      'playerUnits': playerUnitsData,
      'enemyUnits': enemyUnitsData,
      'events': events,
      'outcome': combatResult.playerVictory ? 'Victory' : 'Defeat',
      'turns': combatResult.turnsElapsed,
      'baseName': enemyBaseName,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const navyBlue = Color(0xFF0A2342); // Navy blue color constant
    final textTheme = Theme.of(context).textTheme;
    
    // Update resources and memory
    final resources = ref.watch(resourcesProvider);
    final memoireImmunitaire = ref.watch(memoireImmunitaireProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final authState = ref.watch(authStateProvider);
    final userProfile = ref.watch(userProfileProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Résultats du Combat'),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Results header
          Card(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: combatResult.playerVictory
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    child: Icon(
                      combatResult.playerVictory ? Icons.check_circle : Icons.cancel,
                      size: 60,
                      color: combatResult.playerVictory ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    combatResult.playerVictory ? 'VICTOIRE !' : 'DÉFAITE...',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: combatResult.playerVictory ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    'Combat contre ${enemyBaseName}',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Durée: ${combatResult.turnsElapsed} tours',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          
          // Rewards card
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
                  Text(
                    'Récompenses obtenues:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildRewardItem(
                    context,
                    Icons.flash_on,
                    'Énergie',
                    '+${combatResult.resourcesGained}',
                    Colors.amber[700]!,
                  ),
                  const SizedBox(height: 12),
                  _buildRewardItem(
                    context,
                    Icons.psychology,
                    'Points de Recherche',
                    '+${combatResult.researchPointsGained}',
                    Colors.purple[700]!,
                  ),
                  
                  if (combatResult.pathogenIdsDefeated.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Signatures pathogènes acquises:',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...combatResult.pathogenIdsDefeated.map((id) {
                      final pathogen = enemyPathogens.firstWhere(
                        (p) => p.id == id,
                        orElse: () => enemyPathogens.first,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.memory, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              pathogen.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Ajouté à la mémoire',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          
          // Gemini AI Battle Chronicle
          Card(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Rapports Analytiques IA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                BattleChronicleWidget(battleData: _prepareBattleData()),
              ]),
            ),
          ),
          
          // Combat statistics
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
                    'Statistiques de combat:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Calculate combat stats
                  _buildStatisticItem(
                    context, 
                    'Anticorps déployés', 
                    '${playerAntibodies.length}',
                    Icons.security,
                    Colors.blue,
                  ),
                  
                  _buildStatisticItem(
                    context, 
                    'Pathogènes combattus', 
                    '${enemyPathogens.length}',
                    Icons.coronavirus,
                    Colors.red,
                  ),
                  
                  _buildStatisticItem(
                    context, 
                    'Tours de combat', 
                    '${combatResult.turnsElapsed}',
                    Icons.timer,
                    Colors.orange,
                  ),
                  
                  _buildStatisticItem(
                    context, 
                    'Pathogènes vaincus', 
                    '${combatResult.pathogenIdsDefeated.length}/${enemyPathogens.length}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              // Apply rewards
              resources.updateResources();
              resources.consumeEnergie(-combatResult.resourcesGained); // Negative consumption = addition
              memoireImmunitaire.addResearchPoints(combatResult.researchPointsGained);
              
              // Save battle results to Firestore
              if (authState.value != null) {
                final userId = authState.value!.uid;
                final dataSyncService = ref.read(dataSyncServiceProvider);
                
                // Record battle in history
                await firestoreService.recordBattle(
                  userId: userId,
                  enemyBaseName: enemyBaseName,
                  victory: combatResult.playerVictory,
                  rewardPoints: combatResult.researchPointsGained,
                  resourcesGained: combatResult.resourcesGained
                );
                
                // Update user profile with new values
                userProfile.whenData((profile) async {
                  if (profile != null) {
                    await firestoreService.updateUserProfile(userId, {
                      'currentEnergie': resources.currentEnergie,
                      'currentBiomateriaux': resources.currentBiomateriaux,
                      'researchPoints': profile.researchPoints + combatResult.researchPointsGained,
                      'victories': profile.victories + (combatResult.playerVictory ? 1 : 0),
                    });
                  }
                });
                
                // Add pathogen signatures to immune memory if any were defeated
                for (final id in combatResult.pathogenIdsDefeated) {
                  final pathogen = enemyPathogens.firstWhere((p) => p.id == id);
                  await firestoreService.addPathogenSignature(userId, pathogen.name);
                }
                
                // Save data after combat and ensure everything is synced
                await dataSyncService.saveAfterEvent();
                print('Combat results saved and synced: Energy=${resources.currentEnergie}, Research Points gained=${combatResult.researchPointsGained}');
              }
              
              // Return to home
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text('Retour au Centre de Commandement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: navyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRewardItem(
    BuildContext context, 
    IconData icon, 
    String label, 
    String value, 
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatisticItem(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
