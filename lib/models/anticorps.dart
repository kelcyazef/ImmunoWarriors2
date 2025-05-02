import 'dart:math';
import 'agent_pathogene.dart';

/// Base class for all antibody units
class Anticorps {
  final String id;
  final String name;
  int healthPoints;
  final int maxHealthPoints;
  final AttackType attackType;
  final int damage;
  final int initiative; // Higher goes first in combat
  final int energyCost;
  final int biomaterialCost;
  final int productionTime; // In seconds
  
  // Target selection preference
  bool _prioritizeLowHealth = true; // Target low health enemies by default
  
  Anticorps({
    required this.id,
    required this.name,
    required this.maxHealthPoints,
    required this.attackType,
    required this.damage,
    required this.initiative,
    required this.energyCost,
    required this.biomaterialCost,
    required this.productionTime,
  }) : healthPoints = maxHealthPoints;
  
  /// Perform a basic attack
  int attack() {
    return damage;
  }
  
  /// Receive damage from enemy attacks
  void receiveDamage(int amount) {
    healthPoints = max(0, healthPoints - amount);
  }
  
  /// Execute special capability (to be implemented by subclasses)
  void executeSpecialCapability() {
    // Base implementation does nothing
  }
  
  /// Check if antibody is defeated
  bool get isDefeated => healthPoints <= 0;
  
  /// Set target selection preference
  void setPrioritizeLowHealth(bool value) {
    _prioritizeLowHealth = value;
  }
  
  /// Get target selection preference
  bool get prioritizeLowHealth => _prioritizeLowHealth;
  
  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'healthPoints': healthPoints,
      'maxHealthPoints': maxHealthPoints,
      'attackType': attackType.toString(),
      'damage': damage,
      'initiative': initiative,
      'energyCost': energyCost, 
      'biomaterialCost': biomaterialCost,
      'productionTime': productionTime,
      'type': runtimeType.toString(),
    };
  }
}

/// Specialized antibody that focuses on high damage
class AnticorpsOffensif extends Anticorps {
  bool _toxicSalvoReady = true;
  int _toxicSalvoCooldown = 3; // Turns until ready again
  int _toxicSalvoDamageMultiplier = 2; // Double damage for special attack
  int _currentCooldown = 0;
  
  // Getters for private properties
  bool get toxicSalvoReady => _toxicSalvoReady;
  
  AnticorpsOffensif({
    required String id,
    required String name,
    required int maxHealthPoints,
    required AttackType attackType,
    required int damage,
    required int initiative,
    required int energyCost,
    required int biomaterialCost,
    required int productionTime,
    int? toxicSalvoDamageMultiplier,
    int? toxicSalvoCooldown,
  }) : 
    _toxicSalvoDamageMultiplier = toxicSalvoDamageMultiplier ?? 2,
    _toxicSalvoCooldown = toxicSalvoCooldown ?? 3,
    super(
      id: id,
      name: name,
      maxHealthPoints: maxHealthPoints,
      attackType: attackType,
      damage: damage,
      initiative: initiative,
      energyCost: energyCost,
      biomaterialCost: biomaterialCost,
      productionTime: productionTime,
    );
  
  /// Special capability: Toxic Salvo (area attack)
  @override
  void executeSpecialCapability() {
    if (_toxicSalvoReady) {
      _toxicSalvoReady = false;
      _currentCooldown = _toxicSalvoCooldown;
    }
  }
  
  /// Override attack to include toxic salvo
  @override
  int attack() {
    if (_toxicSalvoReady) {
      executeSpecialCapability();
      return damage * _toxicSalvoDamageMultiplier;
    }
    return super.attack();
  }
  
  /// Update cooldown at end of turn
  void updateCooldown() {
    if (!_toxicSalvoReady && _currentCooldown > 0) {
      _currentCooldown--;
      if (_currentCooldown <= 0) {
        _toxicSalvoReady = true;
      }
    }
  }
  
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['toxicSalvoReady'] = _toxicSalvoReady;
    map['toxicSalvoCooldown'] = _toxicSalvoCooldown;
    map['toxicSalvoDamageMultiplier'] = _toxicSalvoDamageMultiplier;
    map['currentCooldown'] = _currentCooldown;
    return map;
  }
  
  factory AnticorpsOffensif.fromMap(Map<String, dynamic> map) {
    return AnticorpsOffensif(
      id: map['id'],
      name: map['name'],
      maxHealthPoints: map['maxHealthPoints'],
      attackType: AttackType.values.firstWhere(
        (e) => e.toString() == map['attackType'],
        orElse: () => AttackType.physical,
      ),
      damage: map['damage'],
      initiative: map['initiative'],
      energyCost: map['energyCost'],
      biomaterialCost: map['biomaterialCost'],
      productionTime: map['productionTime'],
      toxicSalvoDamageMultiplier: map['toxicSalvoDamageMultiplier'],
      toxicSalvoCooldown: map['toxicSalvoCooldown'],
    );
  }
}

/// Specialized antibody that focuses on healing and support
class AnticorpsDefensif extends Anticorps {
  int _healAmount = 10;
  bool _cellularRepairReady = true;
  int _cellularRepairCooldown = 2; // Turns until ready again
  int _currentCooldown = 0;
  
  // Getters for private properties
  bool get cellularRepairReady => _cellularRepairReady;
  
  AnticorpsDefensif({
    required String id,
    required String name,
    required int maxHealthPoints,
    required AttackType attackType,
    required int damage,
    required int initiative,
    required int energyCost,
    required int biomaterialCost,
    required int productionTime,
    int? healAmount,
    int? cellularRepairCooldown,
  }) : 
    _healAmount = healAmount ?? 10,
    _cellularRepairCooldown = cellularRepairCooldown ?? 2,
    super(
      id: id,
      name: name,
      maxHealthPoints: maxHealthPoints,
      attackType: attackType,
      damage: damage,
      initiative: initiative,
      energyCost: energyCost,
      biomaterialCost: biomaterialCost,
      productionTime: productionTime,
    );
  
  /// Special capability: Cellular Repair (healing)
  @override
  void executeSpecialCapability() {
    if (_cellularRepairReady) {
      _cellularRepairReady = false;
      _currentCooldown = _cellularRepairCooldown;
    }
  }
  
  /// Heal an ally
  int heal() {
    if (_cellularRepairReady) {
      executeSpecialCapability();
      return _healAmount;
    }
    return 0;
  }
  
  /// Update cooldown at end of turn
  void updateCooldown() {
    if (!_cellularRepairReady && _currentCooldown > 0) {
      _currentCooldown--;
      if (_currentCooldown <= 0) {
        _cellularRepairReady = true;
      }
    }
  }
  
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['healAmount'] = _healAmount;
    map['cellularRepairReady'] = _cellularRepairReady;
    map['cellularRepairCooldown'] = _cellularRepairCooldown;
    map['currentCooldown'] = _currentCooldown;
    return map;
  }
  
  factory AnticorpsDefensif.fromMap(Map<String, dynamic> map) {
    return AnticorpsDefensif(
      id: map['id'],
      name: map['name'],
      maxHealthPoints: map['maxHealthPoints'],
      attackType: AttackType.values.firstWhere(
        (e) => e.toString() == map['attackType'],
        orElse: () => AttackType.physical,
      ),
      damage: map['damage'],
      initiative: map['initiative'],
      energyCost: map['energyCost'],
      biomaterialCost: map['biomaterialCost'],
      productionTime: map['productionTime'],
      healAmount: map['healAmount'],
      cellularRepairCooldown: map['cellularRepairCooldown'],
    );
  }
}

/// Specialized antibody that marks targets for increased damage
class AnticorpsMarqueur extends Anticorps {
  double _markingDamageIncrease = 0.5; // 50% damage increase
  bool _targetMarkingReady = true;
  int _targetMarkingCooldown = 1; // Turns until ready again
  int _currentCooldown = 0;
  
  // Getters for private properties
  bool get targetMarkingReady => _targetMarkingReady;
  
  AnticorpsMarqueur({
    required String id,
    required String name,
    required int maxHealthPoints,
    required AttackType attackType,
    required int damage,
    required int initiative,
    required int energyCost,
    required int biomaterialCost,
    required int productionTime,
    double? markingDamageIncrease,
    int? targetMarkingCooldown,
  }) : 
    _markingDamageIncrease = markingDamageIncrease ?? 0.5,
    _targetMarkingCooldown = targetMarkingCooldown ?? 1,
    super(
      id: id,
      name: name,
      maxHealthPoints: maxHealthPoints,
      attackType: attackType,
      damage: damage,
      initiative: initiative,
      energyCost: energyCost,
      biomaterialCost: biomaterialCost,
      productionTime: productionTime,
    );
  
  /// Special capability: Target Marking (increase damage)
  @override
  void executeSpecialCapability() {
    if (_targetMarkingReady) {
      _targetMarkingReady = false;
      _currentCooldown = _targetMarkingCooldown;
    }
  }
  
  /// Get marking damage increase factor
  double getMarkingFactor() {
    if (_targetMarkingReady) {
      executeSpecialCapability();
      return 1.0 + _markingDamageIncrease;
    }
    return 1.0;
  }
  
  /// Update cooldown at end of turn
  void updateCooldown() {
    if (!_targetMarkingReady && _currentCooldown > 0) {
      _currentCooldown--;
      if (_currentCooldown <= 0) {
        _targetMarkingReady = true;
      }
    }
  }
  
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['markingDamageIncrease'] = _markingDamageIncrease;
    map['targetMarkingReady'] = _targetMarkingReady;
    map['targetMarkingCooldown'] = _targetMarkingCooldown;
    map['currentCooldown'] = _currentCooldown;
    return map;
  }
  
  factory AnticorpsMarqueur.fromMap(Map<String, dynamic> map) {
    return AnticorpsMarqueur(
      id: map['id'],
      name: map['name'],
      maxHealthPoints: map['maxHealthPoints'],
      attackType: AttackType.values.firstWhere(
        (e) => e.toString() == map['attackType'],
        orElse: () => AttackType.physical,
      ),
      damage: map['damage'],
      initiative: map['initiative'],
      energyCost: map['energyCost'],
      biomaterialCost: map['biomaterialCost'],
      productionTime: map['productionTime'],
      markingDamageIncrease: map['markingDamageIncrease'],
      targetMarkingCooldown: map['targetMarkingCooldown'],
    );
  }
}

/// Factory to create different antibody types
class AnticorpsFactory {
  /// Create basic offensive antibody
  static AnticorpsOffensif createLymphocyteT() {
    return AnticorpsOffensif(
      id: 'antibody_t_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Lymphocyte T Cytotoxique',
      maxHealthPoints: 85,
      attackType: AttackType.physical,
      damage: 18,
      initiative: 15,
      energyCost: 25,
      biomaterialCost: 15,
      productionTime: 30, // 30 seconds
    );
  }
  
  /// Create advanced offensive antibody
  static AnticorpsOffensif createKillerCell() {
    return AnticorpsOffensif(
      id: 'antibody_nk_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Natural Killer Cell',
      maxHealthPoints: 100,
      attackType: AttackType.energetic,
      damage: 25,
      initiative: 18,
      energyCost: 40,
      biomaterialCost: 25,
      productionTime: 45, // 45 seconds
      toxicSalvoDamageMultiplier: 3, // Triple damage special attack
    );
  }
  
  /// Create basic defensive/healer antibody
  static AnticorpsDefensif createMacrophage() {
    return AnticorpsDefensif(
      id: 'antibody_macro_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Macrophage',
      maxHealthPoints: 120,
      attackType: AttackType.physical,
      damage: 10,
      initiative: 5,
      energyCost: 30,
      biomaterialCost: 20,
      productionTime: 40, // 40 seconds
      healAmount: 15,
    );
  }
  
  /// Create marker antibody
  static AnticorpsMarqueur createLymphocyteB() {
    return AnticorpsMarqueur(
      id: 'antibody_b_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Lymphocyte B',
      maxHealthPoints: 70,
      attackType: AttackType.chemical,
      damage: 8,
      initiative: 12,
      energyCost: 20,
      biomaterialCost: 15,
      productionTime: 35, // 35 seconds
      markingDamageIncrease: 0.75, // 75% damage increase
    );
  }
}
