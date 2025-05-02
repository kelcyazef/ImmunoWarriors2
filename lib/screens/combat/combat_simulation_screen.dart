import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/anticorps.dart';
import '../../models/agent_pathogene.dart';
import '../../models/combat_manager.dart';
import '../../providers/game_providers.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/auth_providers.dart';
import '../../services/data_sync_service.dart';

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
    final textTheme = Theme.of(context).textTheme;
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
          // Combat visualization
          Expanded(
            flex: 3,
            child: Card(
              color: Colors.white,
              elevation: 4,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Combat title and status
                    Text(
                      'Combat contre ${widget.enemyBaseName}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _isSimulationComplete
                          ? _combatResult?.playerVictory == true
                              ? 'VICTOIRE !'
                              : 'DÉFAITE...'
                          : 'Tour ${combatManager.currentTurn}',
                      style: TextStyle(
                        color: _isSimulationComplete
                            ? _combatResult?.playerVictory == true
                                ? Colors.green
                                : Colors.red
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    // Combat visualization area
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              // Player side
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: constraints.maxWidth / 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'ÉQUIPE IMMUNITAIRE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...combatManager.playerUnits.map(
                                      (unit) => _buildUnitIcon(
                                        context,
                                        unit,
                                        true,
                                        combatManager.isPlayerTurn,
                                      ),
                                    ),
                                    if (combatManager.playerUnits.isEmpty)
                                      const Text('Aucune unité restante'),
                                  ],
                                ),
                              ),

                              // Center divider
                              Positioned(
                                left: constraints.maxWidth / 2 - 1,
                                top: 20,
                                bottom: 20,
                                width: 2,
                                child: Container(
                                  color: Colors.grey[300],
                                ),
                              ),

                              // Enemy side
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                width: constraints.maxWidth / 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'PATHOGÈNES HOSTILES',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...combatManager.enemyUnits.map(
                                      (unit) => _buildUnitIcon(
                                        context,
                                        unit,
                                        false,
                                        !combatManager.isPlayerTurn,
                                      ),
                                    ),
                                    if (combatManager.enemyUnits.isEmpty)
                                      const Text('Aucune unité restante'),
                                  ],
                                ),
                              ),

                              if (_isSimulationComplete)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.5),
                                    child: Center(
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
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Combat log
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Journal de Combat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
    final baseColor = isPlayerUnit ? Colors.blue : Colors.red;
    
    // Icon based on unit type
    IconData unitIcon;
    if (unit.isAnticorps) {
      final antibody = unit.unit as Anticorps;
      if (antibody is AnticorpsOffensif) {
        unitIcon = Icons.security;
      } else if (antibody is AnticorpsDefensif) {
        unitIcon = Icons.healing;
      } else if (antibody is AnticorpsMarqueur) {
        unitIcon = Icons.track_changes;
      } else {
        unitIcon = Icons.shield;
      }
    } else {
      final pathogen = unit.unit as AgentPathogene;
      if (pathogen is Virus) {
        unitIcon = Icons.bug_report;
      } else if (pathogen is Bacterie) {
        unitIcon = Icons.coronavirus;
      } else if (pathogen is Champignon) {
        unitIcon = Icons.spa;
      } else {
        unitIcon = Icons.help;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? baseColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: baseColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: healthPercentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  healthPercentage > 0.6
                      ? Colors.green
                      : healthPercentage > 0.3
                          ? Colors.orange
                          : Colors.red,
                ),
                strokeWidth: 3,
              ),
              Icon(
                unitIcon,
                color: baseColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  unit.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'PV: ${unit.healthPoints}/${unit.maxHealthPoints}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(BuildContext context, CombatLogEntry log) {
    final bool isPlayerAction = log.actorId != null &&
        widget.playerAntibodies.any((a) => a.id == log.actorId);
    
    final Color textColor = log.isSpecialAction
        ? Colors.purple
        : isPlayerAction
            ? Colors.blue[700]!
            : Colors.red[700]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: log.isSpecialAction ? FontWeight.bold : FontWeight.normal,
              ),
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
                
                // Perform a full data sync to ensure everything is saved
                await dataSyncService.syncUserDataToFirestore();
                print('Combat results synced to Firestore: Energy=${resources.currentEnergie}, Research Points gained=${combatResult.researchPointsGained}');
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
