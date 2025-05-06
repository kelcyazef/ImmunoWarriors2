import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/anticorps.dart';
import '../../models/agent_pathogene.dart';
import '../../models/combat_manager.dart';
import '../../providers/game_providers.dart';
import 'combat_simulation_screen.dart';

/// An enhanced combat screen with game-like visuals
class ImprovedCombatScreen extends ConsumerStatefulWidget {
  final String enemyBaseName;
  final List<Anticorps> playerAntibodies;
  final List<AgentPathogene> enemyPathogens;

  const ImprovedCombatScreen({
    super.key,
    required this.enemyBaseName,
    required this.playerAntibodies,
    required this.enemyPathogens,
  });

  @override
  ConsumerState<ImprovedCombatScreen> createState() => _ImprovedCombatScreenState();
}

class _ImprovedCombatScreenState extends ConsumerState<ImprovedCombatScreen> with TickerProviderStateMixin {
  // Combat state
  bool _combatEnded = false;
  CombatResult? _combatResult;
  Timer? _combatTimer;
  int _remainingSeconds = 60; // combat timer
  final List<CombatLogEntry> _visibleLogs = [];
  bool _turnInProgress = false;
  List<TurnResult> _turnResults = [];
  List<String> _combatLog = [];
  
  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _cellAttackController;
  final Map<String, AnimationController> _cellAnimControllers = {};
  
  // Combat units and their positions
  final List<CombatUnit> _activeCombatUnits = [];
  final Map<String, Offset> _unitPositions = {};
  final Map<String, Offset> _unitTargetPositions = {};
  
  // Attack effect tracking
  final Map<String, bool> _unitAttacking = {};
  final Map<String, String> _unitAttackTarget = {};
  final Map<String, bool> _unitDying = {};
  
  // Visual and positioning
  final double _cellSize = 65.0;
  final double _fieldWidth = 380.0;
  final double _fieldHeight = 380.0;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 40),
      vsync: this,
    )..repeat();
    
    _cellAttackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Setup combat environment
    _setupInitialPositions();
    
    // Start combat after a brief delay to allow UI to build
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startCombat();
      }
    });
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    _cellAttackController.dispose();
    
    // Dispose all unit animation controllers
    for (final controller in _cellAnimControllers.values) {
      controller.dispose();
    }
    
    // Cancel timer
    _combatTimer?.cancel();
    
    super.dispose();
  }
  
  void _setupInitialPositions() {
    // Create combat units for player antibodies
    for (final antibody in widget.playerAntibodies) {
      final unit = CombatUnit(unit: antibody, isPlayerUnit: true);
      _activeCombatUnits.add(unit);
      
      // Create animation controller for this unit
      _cellAnimControllers[unit.id] = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      )..repeat(reverse: true);
      
      // Initialize state trackers
      _unitAttacking[unit.id] = false;
      _unitDying[unit.id] = false;
      
      // Place on left side of the field
      _unitPositions[unit.id] = Offset(
        _cellSize / 2 + _random.nextDouble() * (_fieldWidth * 0.3),
        _cellSize + _random.nextDouble() * (_fieldHeight - _cellSize * 2),
      );
      _unitTargetPositions[unit.id] = _unitPositions[unit.id]!;
    }
    
    // Create combat units for enemy pathogens
    for (final pathogen in widget.enemyPathogens) {
      final unit = CombatUnit(unit: pathogen, isPlayerUnit: false);
      _activeCombatUnits.add(unit);
      
      // Create animation controller for this unit
      _cellAnimControllers[unit.id] = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      )..repeat(reverse: true);
      
      // Initialize state trackers
      _unitAttacking[unit.id] = false;
      _unitDying[unit.id] = false;
      
      // Place on right side of the field
      _unitPositions[unit.id] = Offset(
        _fieldWidth - _cellSize / 2 - _random.nextDouble() * (_fieldWidth * 0.3),
        _cellSize + _random.nextDouble() * (_fieldHeight - _cellSize * 2),
      );
      _unitTargetPositions[unit.id] = _unitPositions[unit.id]!;
    }
  }
  
  void _startCombat() {
    setState(() {
      _combatEnded = false;
    });
    
    // Start timer
    _combatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          
          // Force end combat if time runs out
          if (_remainingSeconds <= 0) {
            timer.cancel();
            _endCombat();
          }
        });
      }
    });
    
    // Start combat
    final combatManager = ref.read(combatManagerProvider);
    combatManager.startCombat(
      widget.playerAntibodies,
      widget.enemyPathogens,
    );
    
    // Begin turn processing
    _runCombatSimulation(combatManager);
  }
  
  Future<void> _runCombatSimulation(CombatManager combatManager) async {
    while (!_combatEnded && mounted) {
      await _processTurn(combatManager);
    }
  }
  
  Future<void> _processTurn(CombatManager combatManager) async {
    if (_turnInProgress || _combatEnded) return;
    
    setState(() {
      _turnInProgress = true;
    });
    
    try {
      final turnResult = await combatManager.processTurn();
      
      await _processTurnResult(turnResult);
      
      // End combat if needed
      if (turnResult.combatEnded) {
        _endCombat();
      }
    } finally {
      if (mounted) {
        setState(() {
          _turnInProgress = false;
        });
      }
    }
    
    // Delay between turns
    await Future.delayed(const Duration(milliseconds: 200));
  }
  
  Future<void> _processTurnResult(TurnResult turnResult) async {
    // Store the turn result
    _turnResults.add(turnResult);
    
    // Add log entries to combat log
    for (final entry in turnResult.logEntries) {
      setState(() {
        _combatLog.add(entry.message);
        _visibleLogs.add(entry);
        
        // Keep only the last 10 visible logs
        if (_visibleLogs.length > 10) {
          _visibleLogs.removeRange(0, _visibleLogs.length - 10);
        }
      });
    }
    
    if (mounted) {
      
      // Process attack animations
      for (final entry in turnResult.logEntries) {
        // Skip entries without both actor and target
        if (entry.actorId == null || entry.targetId == null || entry.damage == null) {
          continue;
        }
        
        // Only process attack actions
        if (entry.action == CombatAction.attack) {
          await _animateAttack(entry.actorId!, entry.targetId!, entry.damage!);
        }
      }
      
      // Process unit deaths (given as part of TurnResult)
      for (final deadUnit in turnResult.deadUnits) {
        await _animateUnitDeath(deadUnit.id);
      }
    }
  }
  
  Future<void> _animateAttack(String attackerId, String targetId, int damage) async {
    if (!mounted) return;
    
    setState(() {
      _unitAttacking[attackerId] = true;
      _unitAttackTarget[attackerId] = targetId;
    });
    
    _cellAttackController.reset();
    await _cellAttackController.forward().orCancel;
    
    if (mounted) {
      setState(() {
        _unitAttacking[attackerId] = false;
      });
    }
  }
  
  Future<void> _animateUnitDeath(String unitId) async {
    if (!mounted) return;
    
    setState(() {
      _unitDying[unitId] = true;
    });
    
    final controller = _cellAnimControllers[unitId];
    if (controller != null) {
      controller.reset();
      await controller.forward().orCancel;
    }
    
    if (mounted) {
      setState(() {
        // Remove unit from active units if it's still there
        _activeCombatUnits.removeWhere((unit) => unit.id == unitId);
      });
    }
  }
  
  void _endCombat() {
    setState(() {
      _combatEnded = true;
    });
    
    _combatTimer?.cancel();
    
    // Finalize combat and get results
    final combatManager = ref.read(combatManagerProvider);
    _combatResult = combatManager.finalizeCombat();
    
    // Show results after a brief delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Navigate to the combat results screen with AI analytics
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => CombatResultScreen(
            enemyBaseName: widget.enemyBaseName,
            combatResult: _combatResult!,
            playerAntibodies: widget.playerAntibodies,
            enemyPathogens: widget.enemyPathogens,
          ),
        ));
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar (timer, team info)
            _buildStatusBar(),
            
            // Main combat area
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Background battlefield
                  SizedBox.expand(
                    child: CustomPaint(
                      painter: GameBattlefieldPainter(
                        progress: _backgroundController.value,
                      ),
                    ),
                  ),
                  
                  // Combat arena
                  _buildCombatArena(),
                  
                  // Attack lines
                  _buildAttackLines(),
                ],
              ),
            ),
            
            // Combat log
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(10),
                child: _buildCombatLog(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusBar() {
    final playerUnits = _activeCombatUnits.where((unit) => unit.isPlayerUnit).toList();
    final enemyUnits = _activeCombatUnits.where((unit) => !unit.isPlayerUnit).toList();
    
    // Calculate team health percentages
    final playerTotalHealth = playerUnits.fold<int>(0, (sum, unit) => sum + unit.currentHealth);
    final playerMaxHealth = playerUnits.fold<int>(0, (sum, unit) => sum + unit.maxHealth);
    final playerHealthPercent = playerMaxHealth > 0 ? playerTotalHealth / playerMaxHealth : 0.0;
    
    final enemyTotalHealth = enemyUnits.fold<int>(0, (sum, unit) => sum + unit.currentHealth);
    final enemyMaxHealth = enemyUnits.fold<int>(0, (sum, unit) => sum + unit.maxHealth);
    final enemyHealthPercent = enemyMaxHealth > 0 ? enemyTotalHealth / enemyMaxHealth : 0.0;
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Player team info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Immune System',
                  style: TextStyle(
                    color: Colors.blue.shade300,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: playerHealthPercent,
                  minHeight: 8,
                  backgroundColor: Colors.blue.shade900,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(height: 4),
                Text(
                  'Units: ${playerUnits.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade200,
                  ),
                ),
              ],
            ),
          ),
          
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingSeconds < 10 
                ? Colors.red.withOpacity(0.8) 
                : Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'Time: $_remainingSeconds s',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Enemy team info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.enemyBaseName,
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: enemyHealthPercent,
                  minHeight: 8,
                  backgroundColor: Colors.red.shade900,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 4),
                Text(
                  'Units: ${enemyUnits.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade200,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the combat arena with active units
  Widget _buildCombatArena() {
    return Stack(
      children: [
        for (final unit in _activeCombatUnits) 
          if (!(_unitDying[unit.id] ?? false) || (_unitDying[unit.id]! && _cellAnimControllers[unit.id]!.value < 0.9))
            AnimatedPositioned(
              key: ValueKey('unit_${unit.id}'),
              left: _unitPositions[unit.id]!.dx - _cellSize / 2,
              top: _unitPositions[unit.id]!.dy - _cellSize / 2,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: _buildCombatUnit(unit),
            ),
      ],
    );
  }
  
  // Build attack lines between units
  Widget _buildAttackLines() {
    return CustomPaint(
      size: Size(_fieldWidth, _fieldHeight),
      painter: _EffectsLayer(units: _activeCombatUnits),
      foregroundPainter: _AttackLinesLayer(
        attackers: _unitAttacking.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
        positions: _unitPositions,
        targets: _unitAttackTarget,
        progress: _cellAttackController.value,
      ),
    );
  }
  
  // Build an individual combat unit
  Widget _buildCombatUnit(CombatUnit unit) {
    final isAttacking = _unitAttacking[unit.id] ?? false;
    final scale = 1.0 + (_cellAnimControllers[unit.id]?.value ?? 0) * 0.1;
    final opacity = _unitDying[unit.id] ?? false 
        ? 1 - _cellAnimControllers[unit.id]!.value 
        : 1.0;
    
    return SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: isAttacking ? 1.2 : scale,
          child: Stack(
            children: [
              // Cell visualization
              Center(
                child: unit.isPlayerUnit
                    ? _buildAntibodyVisualization(
                        size: _cellSize,
                        animationValue: _cellAnimControllers[unit.id]!.value,
                        isDying: _unitDying[unit.id] ?? false,
                      )
                    : _buildPathogenVisualization(
                        size: _cellSize,
                        animationValue: _cellAnimControllers[unit.id]!.value,
                        isDying: _unitDying[unit.id] ?? false,
                      ),
              ),
              
              // Health indicator
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: unit.currentHealth / unit.maxHealth,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade800,
                  color: unit.isPlayerUnit ? Colors.blue : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build the combat log display
  Widget _buildCombatLog() {
    return _visibleLogs.isEmpty
        ? const Center(
            child: Text('Combat will begin shortly...', style: TextStyle(color: Colors.white70)),
          )
        : ListView.builder(
            itemCount: _visibleLogs.length,
            reverse: true,
            itemBuilder: (context, index) {
              final log = _visibleLogs[_visibleLogs.length - 1 - index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${log.message}',
                  style: TextStyle(
                    color: log.isPlayerAction ? Colors.blue.shade300 : Colors.red.shade300,
                    fontSize: 13,
                  ),
                ),
              );
            },
          );
  }
  
  // Helper method to build antibody visualization
  Widget _buildAntibodyVisualization({
    required double size,
    required double animationValue,
    required bool isDying,
  }) {
    final paint = Paint()
      ..color = isDying
          ? Colors.blue.withOpacity(0.5 - animationValue * 0.5)
          : Colors.blue.shade300
      ..style = PaintingStyle.fill;

    return CustomPaint(
      size: Size(size, size),
      painter: _AntibodyPainter(
        animationValue: animationValue,
        isDying: isDying,
        paintStyle: paint,
      ),
    );
  }

  // Helper method to build pathogen visualization
  Widget _buildPathogenVisualization({
    required double size,
    required double animationValue,
    required bool isDying,
  }) {
    final paint = Paint()
      ..color = isDying
          ? Colors.red.withOpacity(0.5 - animationValue * 0.5)
          : Colors.red.shade300
      ..style = PaintingStyle.fill;

    return CustomPaint(
      size: Size(size, size),
      painter: _PathogenPainter(
        animationValue: animationValue,
        isDying: isDying,
        paintStyle: paint,
      ),
    );
  }
}

// Helper class for rendering attack lines
class _AttackLinesLayer extends CustomPainter {
  final List<String> attackers;
  final Map<String, Offset> positions;
  final Map<String, String> targets;
  final double progress;
  
  _AttackLinesLayer({
    required this.attackers,
    required this.positions,
    required this.targets,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final attackerId in attackers) {
      final targetId = targets[attackerId];
      if (targetId != null && positions.containsKey(attackerId) && positions.containsKey(targetId)) {
        final startPos = positions[attackerId]!;
        final endPos = positions[targetId]!;
        
        final paint = Paint()
          ..color = Colors.blue.shade400.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        // Draw attack line
        final path = Path();
        path.moveTo(startPos.dx, startPos.dy);
        
        // Calculate progress point
        final currentX = startPos.dx + (endPos.dx - startPos.dx) * progress;
        final currentY = startPos.dy + (endPos.dy - startPos.dy) * progress;
        
        path.lineTo(currentX, currentY);
        canvas.drawPath(path, paint);
        
        // Draw effect at tip
        final effectPaint = Paint()
          ..color = Colors.blue.shade300
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(currentX, currentY), 3 + progress * 2, effectPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant _AttackLinesLayer oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.attackers != attackers;
  }
}

// Helper class for field effects
class _EffectsLayer extends CustomPainter {
  final List<CombatUnit> units;
  
  _EffectsLayer({
    required this.units,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw team zones
    final playerPaint = Paint()
      ..color = Colors.blue.shade900.withOpacity(0.2)
      ..style = PaintingStyle.fill;
      
    final enemyPaint = Paint()
      ..color = Colors.red.shade900.withOpacity(0.2)
      ..style = PaintingStyle.fill;
      
    // Draw zones
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.45, size.height),
      playerPaint,
    );
    
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.55, 0, size.width * 0.45, size.height),
      enemyPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _EffectsLayer oldDelegate) {
    return false; // Static background
  }
}

// Antibody visualization painter
class _AntibodyPainter extends CustomPainter {
  final double animationValue;
  final bool isDying;
  final Paint paintStyle;

  _AntibodyPainter({
    required this.animationValue,
    required this.isDying,
    required this.paintStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    
    // Apply pulsing animation
    final pulseFactor = 1.0 + (0.1 * sin(animationValue * 2 * pi));
    final effectiveRadius = radius * pulseFactor;

    // Draw the main body
    canvas.drawCircle(center, effectiveRadius, paintStyle);

    // Draw the Y-shaped antibody arms
    final armPaint = Paint()
      ..color = paintStyle.color
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    // Calculate the arm positions
    final double armLength = size.width * 0.3;
    final double angle1 = -30 * pi / 180;
    final double angle2 = 30 * pi / 180;
    
    // Base of the Y
    final baseStart = Offset(
      center.dx,
      center.dy + effectiveRadius * 0.7,
    );
    final baseEnd = Offset(
      center.dx,
      center.dy + effectiveRadius + armLength * 0.5,
    );
    
    // Upper arms
    final armEnd1 = Offset(
      baseEnd.dx + armLength * cos(angle1),
      baseEnd.dy + armLength * sin(angle1),
    );
    final armEnd2 = Offset(
      baseEnd.dx + armLength * cos(angle2),
      baseEnd.dy + armLength * sin(angle2),
    );
    
    // Draw the arms
    canvas.drawLine(baseStart, baseEnd, armPaint);
    canvas.drawLine(baseEnd, armEnd1, armPaint);
    canvas.drawLine(baseEnd, armEnd2, armPaint);
  }

  @override
  bool shouldRepaint(covariant _AntibodyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.isDying != isDying;
  }
}

// Pathogen visualization painter
class _PathogenPainter extends CustomPainter {
  final double animationValue;
  final bool isDying;
  final Paint paintStyle;

  _PathogenPainter({
    required this.animationValue,
    required this.isDying,
    required this.paintStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    
    // Apply pulsing animation
    final pulseFactor = 1.0 + (0.1 * sin(animationValue * 2 * pi));
    final effectiveRadius = radius * pulseFactor;

    // Draw the main virus body
    canvas.drawCircle(center, effectiveRadius, paintStyle);

    // Draw spikes around the virus
    final spikePaint = Paint()
      ..color = paintStyle.color
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final spikeCount = 12;
    final spikeLength = effectiveRadius * 0.4;

    for (int i = 0; i < spikeCount; i++) {
      final angle = i * (2 * pi / spikeCount) + animationValue * pi;
      final innerPoint = Offset(
        center.dx + cos(angle) * effectiveRadius,
        center.dy + sin(angle) * effectiveRadius,
      );
      final outerPoint = Offset(
        center.dx + cos(angle) * (effectiveRadius + spikeLength),
        center.dy + sin(angle) * (effectiveRadius + spikeLength),
      );

      canvas.drawLine(innerPoint, outerPoint, spikePaint);
    }

    // Add inner detail
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, effectiveRadius * 0.6, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _PathogenPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.isDying != isDying;
  }
}

// Game battlefield painter
class GameBattlefieldPainter extends CustomPainter {
  final double progress;
  
  GameBattlefieldPainter({
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Background
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    // Grid paint
    final gridPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Draw background
    canvas.drawRect(rect, bgPaint);
    
    // Draw grid lines
    final cellSize = 20.0;
    final rowCount = (size.height / cellSize).ceil();
    final colCount = (size.width / cellSize).ceil();
    
    for (int i = 0; i <= rowCount; i++) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }
    
    for (int i = 0; i <= colCount; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
    }
    
    // Draw decorative hexagons
    final hexPaint = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    final hexCount = 6;
    final hexRadius = size.width * 0.1;
    
    for (int i = 0; i < hexCount; i++) {
      final xPos = _randomPos(size.width, i, hexCount);
      final yPos = _randomPos(size.height, i + 3, hexCount);
      
      _drawHexagon(canvas, Offset(xPos, yPos), hexRadius, hexPaint);
    }
  }
  
  double _randomPos(double max, int seed, int total) {
    // Create a deterministic but seemingly random position
    return max * (0.1 + 0.8 * ((seed * 97) % total) / total);
  }
  
  // Helper to draw hexagon
  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final angles = List.generate(6, (i) => i * (pi / 3));
    
    path.moveTo(
      center.dx + radius * cos(angles[0]),
      center.dy + radius * sin(angles[0]),
    );
    
    for (var i = 1; i < 6; i++) {
      path.lineTo(
        center.dx + radius * cos(angles[i]),
        center.dy + radius * sin(angles[i]),
      );
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant GameBattlefieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
