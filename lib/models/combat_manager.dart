import 'dart:math';
import 'package:flutter/foundation.dart';
import 'agent_pathogene.dart';
import 'anticorps.dart';
import 'memoire_immunitaire.dart';

/// Combat log entry for recording battle events
class CombatLogEntry {
  final String message;
  final DateTime timestamp;
  final String? actorId;
  final String? targetId;
  final int? damage;
  final int? healing;
  final bool isSpecialAction;
  
  CombatLogEntry({
    required this.message,
    this.actorId,
    this.targetId,
    this.damage,
    this.healing,
    this.isSpecialAction = false,
  }) : timestamp = DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'actorId': actorId,
      'targetId': targetId,
      'damage': damage,
      'healing': healing,
      'isSpecialAction': isSpecialAction,
    };
  }
  
  factory CombatLogEntry.fromMap(Map<String, dynamic> map) {
    return CombatLogEntry(
      message: map['message'],
      actorId: map['actorId'],
      targetId: map['targetId'],
      damage: map['damage'],
      healing: map['healing'],
      isSpecialAction: map['isSpecialAction'] ?? false,
    );
  }
}

/// Result of a combat
class CombatResult {
  final bool playerVictory;
  final int turnsElapsed;
  final List<CombatLogEntry> combatLog;
  final int resourcesGained;
  final int researchPointsGained;
  final List<String> pathogenIdsDefeated;
  
  // For Gemini AI battle chronicles
  final List<Map<String, dynamic>>? playerUnits;
  final List<Map<String, dynamic>>? enemyUnits;
  final List<String>? significantEvents;
  
  CombatResult({
    required this.playerVictory,
    required this.turnsElapsed,
    required this.combatLog,
    required this.resourcesGained,
    required this.researchPointsGained,
    required this.pathogenIdsDefeated,
    this.playerUnits,
    this.enemyUnits,
    this.significantEvents,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'playerVictory': playerVictory,
      'turnsElapsed': turnsElapsed,
      'combatLog': combatLog.map((entry) => entry.toMap()).toList(),
      'resourcesGained': resourcesGained,
      'researchPointsGained': researchPointsGained,
      'pathogenIdsDefeated': pathogenIdsDefeated,
      'playerUnits': playerUnits,
      'enemyUnits': enemyUnits,
      'significantEvents': significantEvents,
    };
  }
  
  factory CombatResult.fromMap(Map<String, dynamic> map) {
    final logEntries = (map['combatLog'] as List)
        .map((entryMap) => CombatLogEntry.fromMap(entryMap))
        .toList();
        
    return CombatResult(
      playerVictory: map['playerVictory'],
      turnsElapsed: map['turnsElapsed'],
      combatLog: logEntries,
      resourcesGained: map['resourcesGained'] ?? 0,
      researchPointsGained: map['researchPointsGained'] ?? 0,
      pathogenIdsDefeated: List<String>.from(map['pathogenIdsDefeated'] ?? []),
      playerUnits: map['playerUnits'] != null 
          ? List<Map<String, dynamic>>.from(map['playerUnits'])
          : null,
      enemyUnits: map['enemyUnits'] != null 
          ? List<Map<String, dynamic>>.from(map['enemyUnits']) 
          : null,
      significantEvents: map['significantEvents'] != null 
          ? List<String>.from(map['significantEvents']) 
          : null,
    );
  }
}

/// Unit in combat (can be either antibody or pathogen)
class CombatUnit {
  final dynamic unit; // Either Anticorps or AgentPathogene
  final bool isPlayerUnit;
  bool isMarked = false; // For Target Marking capability
  
  CombatUnit({
    required this.unit,
    required this.isPlayerUnit,
  });
  
  String get id => unit.id;
  String get name => unit.name;
  int get healthPoints => unit.healthPoints;
  int get maxHealthPoints => unit.maxHealthPoints;
  int get initiative => unit.initiative;
  bool get isDefeated => unit.isDefeated;
  
  bool get isAnticorps => unit is Anticorps;
  bool get isPathogene => unit is AgentPathogene;
}

/// Manages combat between player antibodies and enemy pathogens
class CombatManager with ChangeNotifier {
  List<CombatUnit> _combatUnits = [];
  List<CombatLogEntry> _combatLog = [];
  int _currentTurn = 0;
  bool _isPlayerTurn = false;
  bool _isCombatActive = false;
  MemoireImmunitaire? _memoireImmunitaire;
  
  // Getters
  List<CombatUnit> get combatUnits => List.unmodifiable(_combatUnits);
  List<CombatLogEntry> get combatLog => List.unmodifiable(_combatLog);
  int get currentTurn => _currentTurn;
  bool get isCombatActive => _isCombatActive;
  bool get isPlayerTurn => _isPlayerTurn;
  
  // Filtered getters
  List<CombatUnit> get playerUnits => 
      _combatUnits.where((unit) => unit.isPlayerUnit && !unit.isDefeated).toList();
  List<CombatUnit> get enemyUnits => 
      _combatUnits.where((unit) => !unit.isPlayerUnit && !unit.isDefeated).toList();
  bool get allEnemiesDefeated => enemyUnits.isEmpty;
  bool get allPlayerUnitsDefeated => playerUnits.isEmpty;
  
  /// Set the memory system to apply bonuses
  void setMemoireImmunitaire(MemoireImmunitaire memoire) {
    _memoireImmunitaire = memoire;
  }
  
  /// Start a new combat between player antibodies and enemy pathogens
  void startCombat(List<Anticorps> playerAntibodies, List<AgentPathogene> enemyPathogens) {
    // Reset combat state
    _combatUnits = [];
    _combatLog = [];
    _currentTurn = 0;
    _isCombatActive = true;
    
    // Add player units
    for (final antibody in playerAntibodies) {
      _combatUnits.add(CombatUnit(unit: antibody, isPlayerUnit: true));
    }
    
    // Add enemy units
    for (final pathogen in enemyPathogens) {
      _combatUnits.add(CombatUnit(unit: pathogen, isPlayerUnit: false));
    }
    
    // Sort units by initiative (higher goes first)
    _combatUnits.sort((a, b) => b.initiative.compareTo(a.initiative));
    
    // Add combat start log entry
    _addLogEntry(
      'Combat initiated: ${playerAntibodies.length} antibody units vs ${enemyPathogens.length} pathogen units',
    );
    
    // Start first turn
    _currentTurn = 1;
    _isPlayerTurn = true;
    
    notifyListeners();
  }
  
  /// Execute automatic combat simulation
  Future<CombatResult> simulateCombat() async {
    if (!_isCombatActive) {
      throw Exception('Cannot simulate combat: no active combat');
    }
    
    // Maximum number of turns to prevent infinite loops
    const maxTurns = 50;
    
    while (_isCombatActive && _currentTurn < maxTurns) {
      // Process each unit's turn in initiative order
      for (final unit in _combatUnits) {
        if (unit.isDefeated) continue;
        
        if (unit.isPlayerUnit) {
          _processPlayerUnitTurn(unit);
        } else {
          _processEnemyUnitTurn(unit);
        }
        
        // Check if combat should end
        if (allEnemiesDefeated || allPlayerUnitsDefeated) {
          _endCombat();
          break;
        }
      }
      
      // Advance to next turn
      if (_isCombatActive) {
        _currentTurn++;
        notifyListeners();
      }
    }
    
    // Force end if max turns reached
    if (_isCombatActive && _currentTurn >= maxTurns) {
      _addLogEntry('Combat timeout reached after $maxTurns turns.');
      _endCombat();
    }
    
    // Calculate results
    return _calculateCombatResult();
  }
  
  /// Process turn for a player unit (antibody)
  void _processPlayerUnitTurn(CombatUnit unit) {
    if (enemyUnits.isEmpty) return;
    
    // Select target based on unit's targeting preference
    CombatUnit target = _selectTarget(unit, enemyUnits);
    
    // Apply damage bonus from immune memory if available
    double damageMultiplier = 1.0;
    if (_memoireImmunitaire != null && target.isPathogene) {
      damageMultiplier += _memoireImmunitaire!.getDamageBonus(target.id);
    }
    
    // Handle special capabilities
    if (unit.unit is AnticorpsOffensif) {
      final offensiveUnit = unit.unit as AnticorpsOffensif;
      
      // Execute special ability if ready
      final attackDamage = (offensiveUnit.attack() * damageMultiplier).round();
      
      // Apply damage to target
      if (target.unit is AgentPathogene) {
        final pathogen = target.unit as AgentPathogene;
        final damageDealt = pathogen.receiveDamage(
          attackDamage, 
          offensiveUnit.attackType
        );
        
        // Log the attack
        if (offensiveUnit.toxicSalvoReady) {
          _addLogEntry(
            '${unit.name} unleashed Toxic Salvo on ${target.name} for $damageDealt damage!',
            actorId: unit.id,
            targetId: target.id,
            damage: damageDealt,
            isSpecialAction: true,
          );
        } else {
          _addLogEntry(
            '${unit.name} attacked ${target.name} for $damageDealt damage',
            actorId: unit.id,
            targetId: target.id,
            damage: damageDealt,
          );
        }
        
        // Update cooldown
        offensiveUnit.updateCooldown();
      }
    } else if (unit.unit is AnticorpsDefensif) {
      final defensiveUnit = unit.unit as AnticorpsDefensif;
      
      // Decide whether to heal or attack
      final shouldHeal = playerUnits.any((u) => 
        u != unit && 
        !u.isDefeated && 
        u.healthPoints < u.maxHealthPoints * 0.7
      );
      
      if (shouldHeal && defensiveUnit.cellularRepairReady) {
        // Find ally with lowest health percentage
        final allyToHeal = playerUnits
            .where((u) => u != unit && !u.isDefeated)
            .reduce((a, b) => 
                (a.healthPoints / a.maxHealthPoints) < (b.healthPoints / b.maxHealthPoints) ? a : b);
        
        // Apply healing
        final healAmount = defensiveUnit.heal();
        if (allyToHeal.unit is Anticorps) {
          final ally = allyToHeal.unit as Anticorps;
          final oldHealth = ally.healthPoints;
          ally.healthPoints = min(ally.maxHealthPoints, ally.healthPoints + healAmount);
          final actualHealing = ally.healthPoints - oldHealth;
          
          // Log the healing
          _addLogEntry(
            '${unit.name} used Cellular Repair on ${allyToHeal.name} for $actualHealing healing',
            actorId: unit.id,
            targetId: allyToHeal.id,
            healing: actualHealing,
            isSpecialAction: true,
          );
        }
      } else {
        // Attack instead
        final attackDamage = (defensiveUnit.attack() * damageMultiplier).round();
        
        // Apply damage to target
        if (target.unit is AgentPathogene) {
          final pathogen = target.unit as AgentPathogene;
          final damageDealt = pathogen.receiveDamage(
            attackDamage, 
            defensiveUnit.attackType
          );
          
          // Log the attack
          _addLogEntry(
            '${unit.name} attacked ${target.name} for $damageDealt damage',
            actorId: unit.id,
            targetId: target.id,
            damage: damageDealt,
          );
        }
      }
      
      // Update cooldown
      defensiveUnit.updateCooldown();
    } else if (unit.unit is AnticorpsMarqueur) {
      final markerUnit = unit.unit as AnticorpsMarqueur;
      
      // Mark the target if ability is ready
      if (markerUnit.targetMarkingReady) {
        // Apply marking
        target.isMarked = true;
        final markingFactor = markerUnit.getMarkingFactor();
        
        // Log the marking
        _addLogEntry(
          '${unit.name} marked ${target.name}, increasing damage by ${((markingFactor - 1) * 100).toInt()}%',
          actorId: unit.id,
          targetId: target.id,
          isSpecialAction: true,
        );
      }
      
      // Attack
      final attackDamage = (markerUnit.attack() * damageMultiplier).round();
      
      // Apply damage to target
      if (target.unit is AgentPathogene) {
        final pathogen = target.unit as AgentPathogene;
        final damageDealt = pathogen.receiveDamage(
          attackDamage, 
          markerUnit.attackType
        );
        
        // Log the attack
        _addLogEntry(
          '${unit.name} attacked ${target.name} for $damageDealt damage',
          actorId: unit.id,
          targetId: target.id,
          damage: damageDealt,
        );
      }
      
      // Update cooldown
      markerUnit.updateCooldown();
    } else {
      // Basic antibody attack
      final antibody = unit.unit as Anticorps;
      final attackDamage = (antibody.attack() * damageMultiplier).round();
      
      // Apply damage to target
      if (target.unit is AgentPathogene) {
        final pathogen = target.unit as AgentPathogene;
        final damageDealt = pathogen.receiveDamage(
          attackDamage, 
          antibody.attackType
        );
        
        // Log the attack
        _addLogEntry(
          '${unit.name} attacked ${target.name} for $damageDealt damage',
          actorId: unit.id,
          targetId: target.id,
          damage: damageDealt,
        );
      }
    }
  }
  
  /// Process turn for an enemy unit (pathogen)
  void _processEnemyUnitTurn(CombatUnit unit) {
    if (playerUnits.isEmpty) return;
    
    // Select target from player units
    CombatUnit target = _selectTarget(unit, playerUnits);
    
    // Check if this unit is marked and apply damage multiplier
    double damageMultiplier = unit.isMarked ? 1.5 : 1.0;
    
    // Handle special capabilities based on pathogen type
    if (unit.unit is Virus) {
      final virus = unit.unit as Virus;
      
      // Random chance to use mutation ability
      final random = Random();
      if (random.nextDouble() < 0.2) { // 20% chance
        virus.executeSpecialCapability();
        
        _addLogEntry(
          '${unit.name} underwent Rapid Mutation, changing its attack type!',
          actorId: unit.id,
          isSpecialAction: true,
        );
      }
      
      // Attack
      final attackDamage = (virus.attack() * damageMultiplier).round();
      
      // Apply damage to target
      if (target.unit is Anticorps) {
        final antibody = target.unit as Anticorps;
        antibody.receiveDamage(attackDamage);
        
        // Log the attack
        _addLogEntry(
          '${unit.name} attacked ${target.name} for $attackDamage damage',
          actorId: unit.id,
          targetId: target.id,
          damage: attackDamage,
        );
      }
    } else if (unit.unit is Bacterie) {
      final bacterie = unit.unit as Bacterie;
      
      // Random chance to use biofilm shield
      final random = Random();
      if (random.nextDouble() < 0.3 && bacterie.biofilmActive == false) { // 30% chance if not active
        bacterie.executeSpecialCapability();
        
        _addLogEntry(
          '${unit.name} activated its Biofilm Shield!',
          actorId: unit.id,
          isSpecialAction: true,
        );
      }
      
      // Attack
      final attackDamage = (bacterie.attack() * damageMultiplier).round();
      
      // Apply damage to target
      if (target.unit is Anticorps) {
        final antibody = target.unit as Anticorps;
        antibody.receiveDamage(attackDamage);
        
        // Log the attack
        _addLogEntry(
          '${unit.name} attacked ${target.name} for $attackDamage damage',
          actorId: unit.id,
          targetId: target.id,
          damage: attackDamage,
        );
      }
    } else if (unit.unit is Champignon) {
      final champignon = unit.unit as Champignon;
      
      // Random chance to release spores
      final random = Random();
      if (random.nextDouble() < 0.25 && champignon.sporesReleased == false) { // 25% chance if not active
        champignon.executeSpecialCapability();
        
        _addLogEntry(
          '${unit.name} released Corrosive Spores into the environment!',
          actorId: unit.id,
          isSpecialAction: true,
        );
      }
      
      // Attack with additional spore damage
      final attackDamage = (champignon.attack() * damageMultiplier).round();
      
      // Apply damage to target
      if (target.unit is Anticorps) {
        final antibody = target.unit as Anticorps;
        antibody.receiveDamage(attackDamage);
        
        // Log the attack
        String message = '${unit.name} attacked ${target.name} for $attackDamage damage';
        if (champignon.sporesReleased) {
          message += ' (includes spore damage)';
        }
        
        _addLogEntry(
          message,
          actorId: unit.id,
          targetId: target.id,
          damage: attackDamage,
        );
      }
      
      // If spores are active, apply area effect damage to other units
      if (champignon.sporesReleased) {
        for (final playerUnit in playerUnits) {
          if (playerUnit != target && !playerUnit.isDefeated && playerUnit.unit is Anticorps) {
            final antibody = playerUnit.unit as Anticorps;
            final sporeDamage = champignon.getSporesDamage();
            antibody.receiveDamage(sporeDamage);
            
            _addLogEntry(
              '${playerUnit.name} took $sporeDamage damage from corrosive spores',
              actorId: unit.id,
              targetId: playerUnit.id,
              damage: sporeDamage,
            );
          }
        }
      }
    } else {
      // Basic pathogen attack
      final pathogen = unit.unit as AgentPathogene;
      final attackDamage = (pathogen.attack() * damageMultiplier).round();
      
      // Apply damage to target
      if (target.unit is Anticorps) {
        final antibody = target.unit as Anticorps;
        antibody.receiveDamage(attackDamage);
        
        // Log the attack
        _addLogEntry(
          '${unit.name} attacked ${target.name} for $attackDamage damage',
          actorId: unit.id,
          targetId: target.id,
          damage: attackDamage,
        );
      }
    }
  }
  
  /// Select a target for an attacking unit
  CombatUnit _selectTarget(CombatUnit attacker, List<CombatUnit> potentialTargets) {
    if (potentialTargets.isEmpty) {
      throw Exception('No targets available');
    }
    
    if (attacker.unit is Anticorps) {
      final antibody = attacker.unit as Anticorps;
      
      // Target selection based on antibody preference
      if (antibody.prioritizeLowHealth) {
        // Target enemy with lowest health
        return potentialTargets.reduce((a, b) => 
          a.healthPoints < b.healthPoints ? a : b);
      } else {
        // Target random enemy
        final random = Random();
        return potentialTargets[random.nextInt(potentialTargets.length)];
      }
    } else {
      // For pathogens, simple targeting logic
      // 60% chance to target lowest health, 40% chance random
      final random = Random();
      if (random.nextDouble() < 0.6) {
        // Target player unit with lowest health
        return potentialTargets.reduce((a, b) => 
          a.healthPoints < b.healthPoints ? a : b);
      } else {
        // Target random player unit
        return potentialTargets[random.nextInt(potentialTargets.length)];
      }
    }
  }
  
  /// End the current combat
  void _endCombat() {
    if (!_isCombatActive) return;
    
    final victory = allEnemiesDefeated;
    
    _isCombatActive = false;
    
    // Add combat end log entry
    if (victory) {
      _addLogEntry('Combat ended: VICTORY after $_currentTurn turns');
    } else {
      _addLogEntry('Combat ended: DEFEAT after $_currentTurn turns');
    }
    
    notifyListeners();
  }
  
  /// Calculate the final result of the combat
  CombatResult _calculateCombatResult() {
    final victory = allEnemiesDefeated;
    
    // Calculate rewards based on outcome
    int resourcesGained = 0;
    int researchPointsGained = 0;
    List<String> pathogenIdsDefeated = [];
    
    // Prepare data for Gemini AI
    final List<Map<String, dynamic>> playerUnitData = [];
    final List<Map<String, dynamic>> enemyUnitData = [];
    final List<String> significantEvents = [];
    
    if (victory) {
      // Base rewards
      resourcesGained = 10 + (5 * _currentTurn);
      researchPointsGained = 5;
      
      // Bonus for defeating pathogens
      for (final unit in _combatUnits.where((u) => !u.isPlayerUnit && u.isDefeated)) {
        if (unit.unit is AgentPathogene) {
          final pathogen = unit.unit as AgentPathogene;
          pathogenIdsDefeated.add(pathogen.id);
          
          // Add to memory if available
          if (_memoireImmunitaire != null) {
            _memoireImmunitaire!.addPathogenSignature(pathogen);
          }
          
          // Additional rewards based on pathogen difficulty
          resourcesGained += pathogen.maxHealthPoints ~/ 5;
          researchPointsGained += 2;
        }
      }
    } else {
      // Consolation prizes for defeat
      resourcesGained = 5;
      researchPointsGained = 1;
    }
    
    // Prepare player unit data for Gemini
    for (final unit in _combatUnits.where((u) => u.isPlayerUnit)) {
      if (unit.unit is Anticorps) {
        final antibody = unit.unit as Anticorps;
        playerUnitData.add({
          'name': antibody.name,
          'type': antibody.runtimeType.toString(),
          'hp': antibody.healthPoints,
          'maxHp': antibody.maxHealthPoints,
          'attackType': antibody.attackType.toString(),
        });
      }
    }
    
    // Prepare enemy unit data for Gemini
    for (final unit in _combatUnits.where((u) => !u.isPlayerUnit)) {
      if (unit.unit is AgentPathogene) {
        final pathogen = unit.unit as AgentPathogene;
        enemyUnitData.add({
          'name': pathogen.name,
          'type': pathogen.runtimeType.toString(),
          'hp': pathogen.healthPoints,
          'maxHp': pathogen.maxHealthPoints,
        });
      }
    }
    
    // Extract significant events for the narrative
    for (final entry in _combatLog) {
      if (entry.isSpecialAction || entry.damage != null && entry.damage! > 20) {
        significantEvents.add(entry.message);
      }
    }
    
    // Take only the most interesting events if we have too many
    final eventsForGemini = significantEvents.length > 10 
        ? significantEvents.sublist(0, 5) + significantEvents.sublist(significantEvents.length - 5) 
        : significantEvents;
    
    return CombatResult(
      playerVictory: victory,
      turnsElapsed: _currentTurn,
      combatLog: List.from(_combatLog),
      resourcesGained: resourcesGained,
      researchPointsGained: researchPointsGained,
      pathogenIdsDefeated: pathogenIdsDefeated,
      playerUnits: playerUnitData,
      enemyUnits: enemyUnitData,
      significantEvents: eventsForGemini,
    );
  }
  
  /// Add an entry to the combat log
  void _addLogEntry(
    String message, {
    String? actorId,
    String? targetId,
    int? damage,
    int? healing,
    bool isSpecialAction = false,
  }) {
    _combatLog.add(CombatLogEntry(
      message: message,
      actorId: actorId,
      targetId: targetId,
      damage: damage,
      healing: healing,
      isSpecialAction: isSpecialAction,
    ));
  }
}
